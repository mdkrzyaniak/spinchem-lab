function [O_t, t, rho_t] = runDynamicsSIADensityOperator(rho_0,L,n_steps,dt,O,dim_krylov,tol)

% set up removal of instabilities
% remove_instab = 1 ;


%evolve the system evolving under
n_time = n_steps+1 ;
d = size(L,1) ;

% u = zeros([d,1]);
% u(1:4) = convertToLiouvilleVector(eye(2)) ;

% set up a matrix of observable operators from the input cell array
if isa(O,'cell')
O_mat = zeros([n_obs,d]) ;
n_obs = length(O) ;
    for j = 1:n_obs
        O_mat(j,:) = convertToLiouvilleVector(O{j})' ;
    end
elseif isa(O,'numeric')
   n_obs = size(O,1) ;
   O_mat = O ; 
end

% empty array for observables
t = (0:n_steps) * dt ;
O_t = zeros([n_obs,n_time]) ;

% set up krylov subspace and full space states
c_t = zeros([dim_krylov,1]) ;
c_t(1) = norm(rho_0) ;
rho_t = rho_0 ;

% generate initial krylov subspace
[L_krylov, krylov_basis] = generateKrylovSubspace(L,rho_t,dim_krylov) ;
% create the propagator in the krylov subspace
U_krylov_dt = expm(dt * full(L_krylov)) ;
% set up empty observable operators in krylov subspace
O_krylov = O_mat * krylov_basis ;


% calculate initial observables
O_t(:,1) = O_krylov * c_t ;
 

for k = 1:n_steps
    % check to see if Krylov subspace needs to be re-generated
    if abs(c_t(end)) > tol* norm(c_t)
        % generate initial krylov subspace
        rho_t = krylov_basis * c_t ;
%         plot(1:d,rho_t')
%         drawnow
        [L_krylov, krylov_basis] = generateKrylovSubspace(L,rho_t,dim_krylov) ;
        % create the propagator in the krylov subspace
%         if remove_instab == 0
            U_krylov_dt = expm(dt * full(L_krylov)) ;
%         elseif remove_instab == 1
%             [V,lambda] = eig(full(L_krylov),'vector') ;
%             unstable_modes = (real(lambda)>(0)) ;
%             lambda(unstable_modes) = lambda(unstable_modes) - real(lambda(unstable_modes)) ;
% %             lambda(unstable_modes) = 0 ;
%             exp_lambda_dt = exp(lambda*dt) ;
%             exp_lambda_dt(unstable_modes) = 0 ;
%             U_krylov_dt = V * (exp_lambda_dt.*inv(V)) ;
%             u_krylov = krylov_basis' * u ;
%             v_krylov = U_krylov_dt' * (u_krylov) ;
%             U_krylov_dt = U_krylov_dt *(eye(dim_krylov)+(1/norm(v_krylov)^2)*v_krylov *(u_krylov'-v_krylov'))  ;
%         end

        % set up empty observable operators in krylov subspace
        O_krylov = O_mat * krylov_basis ;

        % set up krylov vector
        c_t = zeros([dim_krylov,1]) ;
        c_t(1) = norm(rho_t) ;
    end
    
    % propagate the state in the krylov subspace
    c_t = U_krylov_dt * c_t ;
    
    % compute observables in the krylov subspace
    O_t(:,k+1) = O_krylov * c_t ;
end

% compute final state vector
rho_t = krylov_basis * c_t ;

end