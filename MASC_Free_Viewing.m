
% MASC Free viewing  Demo

Apply_IOR = 1 ; % need inhibition of return 
Apply_Retina_Transform = 1 ; 
IOR_size = 201  ;  % pixels, 20 percent of the image width 
IOR_sigma = floor(IOR_size/2) ; 
max_fix = 15 ; % set the total number of fixations 

% IOR filter
filt_disk = fspecial('disk',floor(IOR_size/2));
filt_IOR_1 = fspecial('gaussian', [IOR_size IOR_size], IOR_sigma)  ; 
filt_IOR = (filt_disk/max(filt_disk(:))) .* filt_IOR_1./max(filt_IOR_1(:));

% loop here for running this for more images
im_address = '1.jpg';
input_im = imread(im_address) ; % set this to your input image
[filepath,image_name,ext] = fileparts(im_address);

[im_h , im_w , im_d] = size(input_im);

fixations_row = zeros(1,max_fix) ;
fixations_col = zeros(1,max_fix) ;

IOR_map = zeros(im_h,im_w);
priority_map = zeros(im_h,im_w );
fixation_map = zeros(im_h,im_w);

% initial fixations at the center 
row_im_f = floor(im_h/2) ;
col_im_f = floor(im_w/2) ;
    
fixations_row(1)=row_im_f;
fixations_col(1)=col_im_f;

RETINA_PIXDEG = 30 ;   % image pixels per one degree visual angle, depends on your data collection but leave it at this if not sure

for fix = 2:max_fix  % starting from 2 since the first one is at the center 

    if (fix~=2) % to not inhibit initial center fixation 
        fixation_map(row_im_f,col_im_f) = 1 ;
        IOR_map = conv2(fixation_map,filt_IOR,'same') ;
    end

    % Applying Retina Transform
    if(Apply_Retina_Transform)
        RTransformed_im = Retina_Tran( input_im , row_im_f ,col_im_f , floor(im_w/RETINA_PIXDEG)) ;
    else
        RTransformed_im = input_im;
    end

    % Generate the priority/saliency map
    itti = ittikochmap( RTransformed_im , 0);  % the raw Itti-Koch map with NO final smoothing,
    %  I added the second argument to set the smoothing to zero
    sal_itti = itti.master_map_resized ;
    priority_map = sal_itti;

    if(Apply_IOR)
        priority_map = priority_map - IOR_map ;
        priority_map( priority_map < 0 ) = 0 ; % RELU
    end
    
    % project to MASC and get the next fixation along with SC maps
    [ fix_col , fix_row , Vis_SC_frame , Moto_SC_frame , Moto_SC_frame_cross] = ...
        MASC_simple( priority_map , RETINA_PIXDEG , col_im_f , row_im_f) ; 
    
    fixations_row(fix)=fix_row;
    fixations_col(fix)=fix_col;
    
    row_im_f = fix_row;
    col_im_f = fix_col;
    % Output Parameters
    save_output_maps = 1 ; % set to 1 if you want to save the output maps
    output_dir = [pwd,'\',image_name] ; % set this to the directory where you want the output maps saved

    if(save_output_maps)
        if (~exist(output_dir))
            mkdir(output_dir)
        end
        new_image = sprintf('%s/%02d_Vis_Coll.png',output_dir,fix) ;
        imwrite(Vis_SC_frame,new_image) ;

        new_image = sprintf('%s/%02d_Motor_Coll.png',output_dir,fix) ;    
        imwrite(Moto_SC_frame,new_image) ;

        new_image = sprintf('%s/%02d_Motor_Coll_Cross.png',output_dir,fix)  ;
        imwrite(Moto_SC_frame_cross,new_image) ;
        red = uint8([255 0 0]);
        shapeInserter = vision.ShapeInserter('Fill',1 ,'FillColor','Custom','CustomFillColor',red,'Opacity',1);
        Pts = int32([fix_col-4 fix_row-20 8 40 ; fix_col-20 fix_row-4 40 8]);
        fixations_im = input_im ;
        fixations_im = step(shapeInserter, fixations_im, Pts);
        new_image_name = sprintf('%s/%02d_Fixations_%03d_%03d.png',output_dir,fix,fix_col , fix_row) ;
        imwrite(fixations_im,new_image_name)
    end
end

imshow(input_im)
hold on
for i=2:length(fixations_row)
    %line([fixations_col(i-1),fixations_col(i)], [fixations_row(i-1) , fixations_row(i)],'Color','c','LineWidth',.5);
    arrow([fixations_col(i-1),fixations_row(i-1)], [fixations_col(i) , fixations_row(i)],...
        'EdgeColor','r','FaceColor','r','LineWidth',3,'Length',12,'BaseAngle',40,'TipAngle',30)

end
hold off
new_image = sprintf('%s_Eye_movements.png',image_name ) ;
export_fig(gcf, new_image,'-q95')
