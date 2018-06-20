function [ blurred_im ] = Retina_Tran( img , row_im_f ,col_im_f , width_visual_angle)

rows=size(img,1);
cols=size(img,2);

% Break into separate color planes
red=squeeze(img(:,:,1));
green=squeeze(img(:,:,2));
blue=squeeze(img(:,:,3));

% Initialize the library  
svisinit

% Create a resmap
%fprintf('Creating resolution map...\n');
resmap=svisresmap(rows*2,cols*2,'maparc',2*width_visual_angle);

% Create 3 codecs for r, g, and b
%fprintf('Creating codecs...\n');
c1=sviscodec(red);
c2=sviscodec(green);
c3=sviscodec(blue);

% The masks get created when you set the map
%fprintf('Creating blending masks...\n');
svissetresmap(c1,resmap)
svissetresmap(c2,resmap)
svissetresmap(c3,resmap)

% Start the encoding loop
% fprintf('Processing a %d X %d pixel image...\n',cols,rows);
% fprintf('Press ESC to exit...\n');

% Encode
i1=svisencode(c1,row_im_f,col_im_f);
i2=svisencode(c2,row_im_f,col_im_f);
i3=svisencode(c3,row_im_f,col_im_f);

% Put them back together
blurred_im=cat(3,i1,i2,i3);

end



