

MASC free viewing toolbox 

Hossein Adeli, June 2018
hossein.adelijelodar@gmail.com 

Adeli, H., Vitu, F., & Zelinsky, G. J. (2017). A model of the superior colliculus predicts fixation locations during scene viewing and visual search. Journal of Neuroscience, 37(6), 1453-1467.

This demo shows how to use MASC for a scene viewing task, but MASC is a general model of eye-movement. It could be used to generate eye-movements from different priority/saliency maps. We chose to use Itti-Koch Saliency (from the GBVS implementation) for simplicity in our free viewing experiments but you could certainly feed it other saliency maps to check if the generated eye-movements are different. If you are comparing to a model that has rich features (deep learning) then the comparison would be more fair if you also give MASC a saliency map that used similarly rich features. But if you choose to use the Itti-koch saliency, you need to download and install the GBVS toolbox (http://www.vision.caltech.edu/~harel/share/gbvs.php).

You can start with "MASC_Free_Viewing.m" and modify it for your purpose. You can easily replace the line for calling Itti-Koch map with another one. Since we apply retinal transformation to our image which is contingent on the fixation location, the saliency map is generated again after each fixation but you can feed in the same priority map for each fixation if you are not using any fixation contingent transformation on the image (that is you generate the saliency map and then generate few eye-movements from that saliency). If you want to use Retina transformation, dowload this toolbox from the follwing website. 
svistoolbox-1.0.5  (http://svi.cps.utexas.edu/software.shtml)

Refer to the JoN paper for general methods.

These two libraries are needed for visualization: 

1. export_fig  (https://www.mathworks.com/matlabcentral/fileexchange/23629-export-fig)
2. arrow  https://www.mathworks.com/matlabcentral/fileexchange/278-arrow


