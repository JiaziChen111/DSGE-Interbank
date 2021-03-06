%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Need a model written as:
%
% snext=G(s,x,e)
% E F(s,x,e,snext,xnext)=0
%
% Do not forget to add the compecon libraries
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all

%% Addpath libraries

addpath('../../solver_lib')

%% set model name
model_name = 'imperfect';

%% Parameters
none=[];


model = feval( [model_name '_model']);


[s_ss,x_ss]=steady_state(model,model.params);
model.x_ss=x_ss';
model.s_ss=s_ss';

% Define shocks
N_shocks = [5 5];

isigma_z=strmatch('sigma_z',model.parameters, 'exact');
sigma_z=model.params(isigma_z);

isigma_u=strmatch('sigma_u',model.parameters, 'exact');
sigma_u=model.params(isigma_u);

sig = diag( [sigma_z^2 sigma_u^2] );
m = [0 0];
[e,w] = qnwnorm(N_shocks,m,sig);

%% Define the grid
ss = model.s_ss;



% smin = [ 25, 1, 1, -0.025, -0.007 ];
% smax = [ 34, 2.6, 2.6, 0.025, 0.007 ];
% 
smin = [ 26.3, 2.33, 2.33, -0.025, -0.007 ];
smax = [ 28.3, 2.40, 2.40, 0.025, 0.007 ];

% smin = [ 8.6, 1.32, 1.3, -0.025, -0.007 ];
% smax = [ 10.6, 1.38, 1.38, 0.025, 0.007 ];
         
orders = [3, 3, 3, 2, 2];


%% Define interpolator

cdef=fundefn('lin', orders, smin, smax);
nodes = funnode(cdef);
grid = gridmake(nodes);

ns = size(grid,1)


%% Convergence criteria
tol=1e-10;
maxiteration=5000;

%% Initialization using first order d.r.
x_ss = model.x_ss;
s_ss = model.s_ss;
% X_s = model.X{2};
% xinit=x_ss*ones(1,ns)+X_s*(grid'-s_ss*ones(1,ns));
% x=xinit';
X_s=initial_guess(model, model.s_ss, model.x_ss,model.params);
X_s=real(X_s);
xinit=x_ss*ones(1,ns)+X_s*(grid'-s_ss*ones(1,ns));
x=xinit';

%% Iterate
iteration=1;
converge=0;

hom_n = 50;
homvec = linspace(0,1,hom_n);
hom_i = 1;
hom = 0;
err0 = 1e6;

faktor=[1:0.01:2];
nfaktor=length(faktor)

for k=1:nfaktor;
    
    
    
    if k>1;
    smin = [(2-faktor(k))*smin(1:3), smin(4:5)]
    smax = [faktor(k)*smax(1:3), smax(4:5)]
    cdef2=fundefn('lin', orders, smin, smax);
    nodes = funnode(cdef2);
    grid = gridmake(nodes);
    x=funeval(coeff,cdef,grid);
    
    cdef=cdef2;
    disp('Faktor')
    disp(faktor(k))
    
    end;
    
    converge=0;
    iteration=1;
    
    disp('Starting policy rule iteration.');
    disp('_________________________________________________________');
    disp('iter       error        gain    hom   inner    elap.(s)  ');
    disp('_________________________________________________________');

    tic;
    t0 = tic;
    %[coeff,B]=funfitxy(cdef, grid, x);
    while converge==0 && iteration < maxiteration

        [coeff,B]=funfitxy(cdef, grid, x);

        fobj = @(xt) step_residuals_nodiff(grid, xt, e, w, model.params, model, coeff, cdef, hom);
        [x_up, nit] = newton_solver_diff(fobj, x, 50);

        err=sum(sum(abs(x-x_up)));
        if (err < tol);
            converge=1;
        end;

        t1 = tic;
        elapsed = double(t1 - t0)/1e6;
        t0 = t1;

    %     irat=strmatch('rat',model.auxiliaries,'exact');
    %     iperfect=strmatch('perfect',model.auxiliaries,'exact');
    %     aux=model.a(grid,x,model.params);
    %     disp(mean(aux(:,irat)));
    %     disp(mean(aux(:,iperfect)));

        gain=err/err0;
        fprintf('%d\t%e\t%.2f\t%.2f\t%d\t%.2f\n', iteration, err, gain, hom, nit, elapsed)
        %disp(sum(abs(x-x_up)));


        %sum(regime)


        if (err < 1) && (hom_i < hom_n);
            hom_i = hom_i + 1;
            hom = homvec(hom_i);
        end;

        err0 = err;  

        x=x_up;
        iteration = iteration+1;


    end;
    disp('___________ ________________________________');
    toc;

    if iteration > maxiteration
        disp('The model could not be solved');
    end

end;
%% Save the grid
grille.smax= smax;
grille.smin=smin;
grille.orders=orders;
grille.nodes=nodes;
grille.grid=grid;
grille.ns=ns;

grid=grille;


%% Save the rule
rule.x=x;
rule.cdef=cdef;
rule.coeff=coeff;

%% Solve for the risky steady-state
disp('Solving for the risky steady state.');
disp('_________________________________________________________');
ts_rss=risky_steady_state(model,rule);
rule.s_rss=ts_rss';
disp('_________________________________________________________');
%% Save everything
save([model_name '_sol'],'model','grid','rule');
