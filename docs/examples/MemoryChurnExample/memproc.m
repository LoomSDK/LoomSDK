graphics_toolkit ("gnuplot");

params = [-1, -2, 0, 1, 2, 4, 8, 16, 32, 64]
styles = ["+"; "o"; "*"; "."; "x"; "s"; "d"; "h"; "v"; "p"];
memstat = [];

for param = params
  loaded = dlmread(["data/newest/memstat-" num2str(param) ".tsv"], "\t", 1, 0);
  memstat = [memstat; repmat(param, rows(loaded), 1) loaded];
endfor

col_param     = 1
col_allocNum  = 2
col_sampleNum = 3
col_allocTime = 4
col_gcTime    = 5
col_beforeMem = 6
col_afterMem  = 7
col_beforeProcMem = 8
col_afterProcMem  = 9

function retval = getstat(arr, fun)
  [u, ~, j] = unique(arr(:, 2));
  retval = [u accumdim(j', arr(:, 4:end), 1, :, fun)];
endfunction

function retval = coltocols(arr, cols)
  retval = reshape(arr, rows(arr)/cols, cols);
endfunction



function [handles] = scatter_series_set(x_vals, y_vals, sizes, colors, styles)
    N = size(x_vals)(2);
    
    handles = cell([N, 1]);
    
    for ind = 1:N
      if ind > 1
        hold on;
      endif
      
      x_val = x_vals(:, ind);
      x_valp = (1:rows(x_val))';
      
      [u, i, j] = unique(x_val, "first");
      
      handles{ind} = plot(x_valp, y_vals(:, ind));
      
      #ticks = linspace(ticklabel(1), ticklabel(end), numel(x_val))';
      #ticks = floor(linspace(x_val(1), x_val(end), 10)');
      
      set(gca, 'yscale', 'log');
      set(gca, 'xtick', i(1:2:end));
      set(gca, 'xticklabel', u(1:2:end));
      
      set(handles{ind}, 'linestyle', 'none');
      set(handles{ind}, 'marker', styles(ind));
      set(handles{ind}, 'markersize', sizes(ind));
      set(handles{ind}, 'color', colors(ind, :));
    end
    hold off;
end





first = memstat(memstat(:, 1) == -1, :);
second = memstat(memstat(:, 1) == -2, :);
#acc = getstat(first, @mean)

#scatter(
#  repmat((1:prows)', 1, pcols),
#  coltocols(memstat(:, col_allocTime), pcols),
#  8,
#  colors,
#  "."
#);

function plotcol(name, xlab, x, y, params, styles)
  pcols = numel(params);
  prows = rows(x)/pcols;
  cmap = rainbow(pcols);
  scatter_series_set(
    #repmat((1:prows)', 1, pcols),
    coltocols(x, pcols),
    coltocols(y, pcols),
    repmat(2, 1, pcols),
    cmap,
    styles
  );
  legend(num2str(params'), "orientation", "horizontal", "location", "northwestoutside");
  title(name);
  xlabel("allocations (stacked samples)");
  ylabel(xlab);
end

an = memstat(:, col_allocNum);

spw = 2;
sph = 3;

#h = gcf
#set(h, 'PaperUnits','centimeters');
#set(h, 'Units','centimeters');
#pos=get(h,'Position');
#set(h, 'PaperSize', [pos(3) pos(4)]);
#set(h, 'PaperPositionMode', 'manual');
#set(h, 'PaperPosition',[0 0 pos(3) pos(4)]);

#w = 1000;
#h = 1000;

#set(gcf, 'papersize',[0 0 w h]);

#set(gcf, 'renderermode','manual');
#set(gcf, 'renderer','zbuffer');
#set(gcf, 'PaperUnits','centimeters');
#set(gcf, 'Units','centimeters');
#set(gcf, 'PaperPosition',[0 0 10 10]);


set(gcf, "papersize", [800, 6000]);
set(gcf, "paperunits", "normalized");
set(gcf, "paperposition", [0, 0, 1, 1]);
set(gcf, "paperorientation", "portrait");
set(gcf, "units", "normalized");

subplot(sph, spw, 1);
plotcol("allocation time", "ms", an, memstat(:, col_allocTime), params, styles);

subplot(sph, spw, 2);
plotcol("gc time", "ms", an, memstat(:, col_gcTime), params, styles);

subplot(sph, spw, 3);
plotcol("lua memory before gc", "MiB", an, memstat(:, col_beforeMem), params, styles);

subplot(sph, spw, 4);
plotcol("lua memory after gc", "MiB", an, memstat(:, col_afterMem), params, styles);

subplot(sph, spw, 5);
plotcol("process memory before gc", "MiB", an, memstat(:, col_beforeProcMem)/1024/1024, params, styles);

subplot(sph, spw, 6);
plotcol("process memory after gc", "MiB", an, memstat(:, col_afterProcMem)/1024/1024, params, styles);

print LuaTablePrealloc.pdf