
RS.LFP = true;
[meaX, meaY, meaZ] = meshgrid(0:100:2200, 200, 0:100:1200);
RS.meaXpositions = meaX;
RS.meaYpositions = meaY;
RS.meaZpositions = meaZ;
RS.minDistToElectrodeTip = 20;
RS.maxRecTime = 200;
RS.sampleRate = 1000;

RS.v_m = 1:1000:14000;%54560; %49600; %175000;
clear meaX meaY meaZ;