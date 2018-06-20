function [R,phi] = coll2vis(u,v)

RETINA_A = 3.0  ;    
RETINA_BU = 1.4 ;
RETINA_BV = 1.8  ;         
% RETINA_FOVEA = 0.5 ;     
% RETINA_SIGMA = .5 ;

R=RETINA_A*sqrt(exp(2*u/RETINA_BU)-(2*exp(u/RETINA_BU).*cos(v/RETINA_BV))+1) ;
phi=atan((exp(u/RETINA_BU).*sin(v/RETINA_BV))./(exp(u/RETINA_BU).*cos(v/RETINA_BV)-1.0))  ;

% col_diff = int32(RETINA_PIXDEG*R.*cos(phi));
% row_diff = int32(RETINA_PIXDEG*R.*sin(phi));


