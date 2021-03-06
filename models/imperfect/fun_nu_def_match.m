function [ RES] = fun_nu_def_match(var,sigma,match, params)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

nu_def=var(1);
k=var(2);
me=var(3);

beta=params(1);
alpha=params(2);
delta=params(3);
x_ss=params(4);
theta=params(5);

R=(1+x_ss)/(beta);
RL=R;




Phi=1-exp(-(nu_def-me)/sigma);

rk=1/(beta*Phi)+delta-1;


%from (10)
mu= Phi^(1/(theta-1))*(theta-1)/theta;

%from (8)
w=mu*(1-alpha)*k^alpha;

%from (6)
y=Phi^(theta/(theta-1)+alpha-1)*k^alpha;

%from (10bis)
pro=1/(theta-1)*(theta/(theta-1))^(-theta)*(mu)^(1-theta)*y;

%from (11)
RES(1) = w*RL*nu_def - pro+RL*k;
RES(2) = rk-mu*alpha*k^(alpha-1);
RES(3) = match-Phi;


end

