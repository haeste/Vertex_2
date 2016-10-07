% This script is written and read by pdetool and should NOT be edited.
% There are two recommended alternatives:
 % 1) Export the required variables from pdetool and create a MATLAB script
 %    to perform operations on these.
 % 2) Define the problem completely using a MATLAB script. See
 %    http://www.mathworks.com/help/pde/examples/index.html for examples
 %    of this approach.
function pdemodel
[pde_fig,ax]=pdeinit;
pdetool('appl_cb',8);
set(ax,'DataAspectRatio',[1000 450 1]);
set(ax,'PlotBoxAspectRatio',[1 1 1]);
set(ax,'XLim',[0 2000]);
set(ax,'YLim',[0 900]);
set(ax,'XTick',[ -200,...
 -100,...
 0,...
 100,...
 200,...
 300,...
 400,...
 500,...
 600,...
 700,...
 800,...
 900,...
 1000,...
 1100,...
 1200,...
 1300,...
 1400,...
 1500,...
 1600,...
 1700,...
 1800,...
 1900,...
 2000,...
 2100,...
 2200,...
]);
set(ax,'YTick',[ -200,...
 -100,...
 0,...
 100,...
 200,...
 300,...
 400,...
 500,...
 600,...
 700,...
 800,...
 900,...
 1000,...
 1100,...
 1200,...
 1300,...
 1400,...
]);

% Geometry description:
pderect([-2.2040473090277146 1997.7959526909722 1057.7947845804988 -142.20521541950109],'R1');
pdecirc(734.13497700330947,312.38955443758852,5,'C1');
pdecirc(734.31338204277893,300.43881750230963,5,'C2');
set(findobj(get(pde_fig,'Children'),'Tag','PDEEval'),'String','R1-(C1+C2)')

% Boundary conditions:
pdetool('changemode',0)
pdesetbd(12,...
'dir',...
1,...
'1',...
'-200')
pdesetbd(11,...
'dir',...
1,...
'1',...
'-200')
pdesetbd(10,...
'dir',...
1,...
'1',...
'-200')
pdesetbd(9,...
'dir',...
1,...
'1',...
'-200')
pdesetbd(8,...
'dir',...
1,...
'1',...
'200')
pdesetbd(7,...
'dir',...
1,...
'1',...
'200')
pdesetbd(6,...
'dir',...
1,...
'1',...
'200')
pdesetbd(5,...
'dir',...
1,...
'1',...
'200')
pdesetbd(4,...
'dir',...
1,...
'1',...
'0')
pdesetbd(3,...
'dir',...
1,...
'1',...
'0')
pdesetbd(2,...
'dir',...
1,...
'1',...
'0')
pdesetbd(1,...
'dir',...
1,...
'1',...
'0')

% Mesh generation:
setappdata(pde_fig,'Hgrad',1.3);
setappdata(pde_fig,'refinemethod','regular');
setappdata(pde_fig,'jiggle',char('on','mean',''));
setappdata(pde_fig,'MesherVersion','preR2013a');
pdetool('initmesh')
pdetool('refine')
pdetool('refine')
pdetool('refine')
pdetool('jiggle')

% PDE coefficients:
pdeseteq(1,...
'1.0',...
'0.0',...
'0',...
'1.0',...
'0:10',...
'0.0',...
'0.0',...
'[0 100]')
setappdata(pde_fig,'currparam',...
['1.0';...
'0  '])

% Solve parameters:
setappdata(pde_fig,'solveparam',...
char('0','93984','10','pdeadworst',...
'0.5','longest','0','1E-4','','fixed','Inf'))

% Plotflags and user data strings:
setappdata(pde_fig,'plotflags',[1 1 1 1 2 1 1 1 0 0 0 1 1 1 0 1 0 1]);
setappdata(pde_fig,'colstring','');
setappdata(pde_fig,'arrowstring','');
setappdata(pde_fig,'deformstring','');
setappdata(pde_fig,'heightstring','');

% Solve PDE:
pdetool('solve')
