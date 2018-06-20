

function [ col_im_f , row_im_f ,Vis_SC_frame , Moto_SC_frame , Moto_SC_frame_cross ] = ...
    MASC_simple( priority_map , RETINA_PIXDEG , Init_col_im_f , Init_row_im_f)

% UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% --------------------------------------------------------------------
% Parameter Settings
% --------------------------------------------------------------------

clear dir
warning('off', 'Images:initSize:adjustingMag');

% Averaging and Point-Image Parameters
Visual_Point_Image = 1 ;   % set this to zero if you want less avearging 
VISUAL_DIAMETER = 1.6 ; % mm
VISUAL_SIGMA = .4 ; % mm
Motor_Point_Image = 1 ;
MOTOR_DIAMETER = 2.4 ; % mm
MOTOR_SIGMA = .6 ;

ave_across_Coll = 1 ;

% System Parameters
RETINA_A = 3.0;
RETINA_BU = 1.4 ;
RETINA_BV = 1.8  ;
RETINA_FOVEA = 0.5 ;
map_w = 640 ;
map_h = 480 ;
PIX_MM = 76 ;  % map_pixels per mm of SC

% Initialize
[im_h , im_w , im_d] = size(priority_map) ;
if(im_d ~= 1)
    priority_map = mean(priority_map,3);
end

red = uint8([255 0 0]);
x_sign = int32([ones(1,map_w/2),-ones(1,map_w/2)])  ;
y_sign = 1 ;
mask_fill = double(imread('mask_fill.png'));
SC_frame  = double(imread('SC_frame.png'));
load('across_Coll.mat') % Mapping  between colliculus needed for averaging across
filt_v = fspecial('gaussian', [floor(VISUAL_DIAMETER*PIX_MM) floor(VISUAL_DIAMETER*PIX_MM)], floor(VISUAL_SIGMA*PIX_MM))  ;
filt_m = fspecial('gaussian', [floor(MOTOR_DIAMETER*PIX_MM) floor(MOTOR_DIAMETER*PIX_MM)], floor(MOTOR_SIGMA*PIX_MM))  ;

row_im_f = Init_row_im_f ;
col_im_f = Init_col_im_f ;

row_im_m = row_im_f ;
col_im_m = col_im_f ;

sal_project = zeros(map_h,map_w) ;
moto_Coll = zeros(map_h,map_w) ;
Rcoll = zeros(2*map_h,map_w);
Lcoll = zeros(2*map_h,map_w);
% --------------------------------------------------------------------
% Saliency Map in Colliclus - Porjecting and then Applying visual point image
% --------------------------------------------------------------------
col = 1:map_w ;
u = abs( ( col - map_w/2 ) / PIX_MM ) ;
for row=1:map_h
    v = ( ( map_h / 2 ) - row ) ./ PIX_MM ;
    [R,phi] = coll2vis(u,v);
    col_diff = int32(RETINA_PIXDEG*R.*cos(phi));
    row_diff = int32(RETINA_PIXDEG*R.*sin(phi));
    col_im = col_im_f + x_sign .* col_diff;
    row_im = row_im_f + y_sign * row_diff;
    acc_index = (row_im > 0 & row_im < im_h & col_im > 0 & col_im < im_w & ( mask_fill(row,:) < 50 ) );
    sal_project(row,acc_index) = diag(priority_map( row_im(acc_index) , col_im(acc_index) ));
end

if(Visual_Point_Image == 1)
    sal_coll(:,1:map_w/2) = conv2(sal_project(:,1:map_w/2),filt_v,'same') ;
    sal_coll(:,1+map_w/2:map_w) = conv2(sal_project(:,1+map_w/2:map_w),filt_v,'same') ;
    sal_coll = sal_coll .* ( mask_fill < 50 );
else
    sal_coll = sal_project .* ( mask_fill < 50 );
end
[S,I] = max(sal_coll(:)) ;
% check whether the map is completely empty
if( S == 0 )
    return
end
% --------------------------------------------------------------------
% Applying Motor Point Image
% --------------------------------------------------------------------
if(Motor_Point_Image == 1)
    if(ave_across_Coll)
        Lcoll(1+map_h/2:map_h+map_h/2 , 1:map_w/2) = sal_coll(:,1:map_w/2) ;
        Rcoll(1+map_h/2:map_h+map_h/2 , 1+map_w/2:map_w) = sal_coll(:,1+map_w/2:map_w) ;
        moto_Lcoll = conv2(Lcoll,filt_m,'same') ;
        moto_Rcoll = conv2(Rcoll,filt_m,'same') ;
        for row=1:map_h
            col= 1:map_w/2 & ( mask_fill(row,1:map_w/2) < 50 ) ;
            if ~(1 && all(col == 0))
                moto_Coll(row,col)= moto_Lcoll(row+map_h/2 , col) + ...
                    diag(moto_Rcoll(map_h/2 + across_Coll(row,col,1), across_Coll(row,col,2)))' ;
                col=1:map_w & ( mask_fill(row,1:map_w) < 50 ) & [zeros(1,map_w/2),ones(1,map_w/2)] ;
                moto_Coll(row,col)= moto_Rcoll(row+map_h/2 , col) + ...
                    diag(moto_Lcoll(map_h/2 + across_Coll(row,col,1), across_Coll(row,col,2)))' ;
            end
        end
    else  % average across coll
        moto_Coll(:,1:map_w/2) = conv2(sal_coll(:,1:map_w/2),filt_m,'same') ;
        moto_Coll(:,1+map_w/2:map_w) = conv2(sal_coll(:,1+map_w/2:map_w),filt_m,'same') ;
    end
else
    moto_Coll = sal_coll ;
end

moto_Coll = moto_Coll.* ( mask_fill < 50 );

[M,I] = max(moto_Coll(:)) ;
sum_Activity = sum(moto_Coll(:)) ;
[row_m , col_m] = ind2sub([map_h,map_w],I) ;

if (mask_fill(row_m-1,col_m) == 255 || mask_fill(row_m-2,col_m) == 255 )
    row_m = row_m + 2 ;
elseif( mask_fill(row_m+1,col_m) == 255 || mask_fill(row_m+2,col_m) == 255 )
    row_m = row_m - 2 ;
end

% Convert back to image space
u_m = abs( ( col_m - map_w/2 ) / PIX_MM )  ;
v_m = ( ( map_h / 2 ) - row_m ) / PIX_MM   ;
[R,phi] = coll2vis(u_m,v_m);
col_diff = int32(RETINA_PIXDEG*R.*cos(phi));
row_diff = int32(RETINA_PIXDEG*R.*sin(phi));
col_im_m = col_im_f + sign( map_w/2 - col_m ) .* col_diff ;
row_im_m = row_im_f + row_diff ;

if(col_im_m < 1 )
    col_im_m = 1 ;
end
if(row_im_m < 1 )
    row_im_m = 1 ;
end
if(col_im_m > im_w )
    col_im_m = im_w ;
end
if(row_im_m > im_h )
    row_im_m = im_h ;
end
%update the current fixation
row_im_f = double(row_im_m)  ;
col_im_f = double(col_im_m)  ;

% Output image preparation
sal_project_frame = repmat(sal_project/max(sal_project(:)),[1 1 3]);
sal_project_frame(SC_frame ~= 0)= SC_frame(SC_frame ~= 0);

Vis_SC_frame = repmat(sal_coll/max(sal_coll(:)),[1 1 3]);
Vis_SC_frame(SC_frame ~= 0)= SC_frame(SC_frame ~= 0);

Moto_SC_frame = repmat(moto_Coll/max(moto_Coll(:)),[1 1 3]);
Moto_SC_frame(SC_frame ~= 0)= SC_frame(SC_frame ~= 0);

shapeInserter = vision.ShapeInserter('Fill',1 ,'FillColor','Custom','CustomFillColor',red,'Opacity',1);
Pts = int32([col_m-4 row_m-10 8 20 ; col_m-10 row_m-4 20 8]);
Moto_SC_frame_cross = step(shapeInserter, Moto_SC_frame, Pts);

end

%%