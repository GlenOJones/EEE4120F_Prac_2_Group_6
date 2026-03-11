function plot_speedup(filename)
% PLOT_SPEEDUP  Read parallel benchmark CSV data and produce speedup plots.
%
%   plot_speedup()            - uses 'speedup_data.csv' in the current folder
%   plot_speedup('myfile.csv')- uses the specified CSV file
%
%   The CSV must contain columns:
%     Name, Width, Height, Megapixels, Max_Workers,
%     T_Serial, T_Parallel, Speedup

    if nargin < 1
        filename = 'speedup_data.csv';
    end

    %% ── 1. Read data ──────────────────────────────────────────────────────
    T = readtable(filename, 'TextType', 'string');

    % Unique resolution names (in order of increasing megapixels)
    [~, sortIdx] = sort(T.Megapixels);
    allNames     = T.Name(sortIdx);
    resNames     = unique(allNames, 'stable');   % preserves MP order

    % Unique worker counts (sorted)
    workerCounts = unique(T.Max_Workers);

    % Strip path and extension for use as plot title
    [~, fileTitle, ~] = fileparts(filename);
    fileTitle = strrep(fileTitle, '_', ' ');  % replace underscores with spaces

    %% ── 2. Colour palette (one colour per worker count) ───────────────────
    cmap = lines(numel(workerCounts));

    %% ── 3. Figure 1 – Speedup vs Resolution (one line per worker count) ───
    figure('Name', 'Speedup vs Resolution', 'NumberTitle', 'off', ...
           'Position', [100 100 860 520]);

    hold on;
    hLines = gobjects(numel(workerCounts), 1);

    for wi = 1:numel(workerCounts)
        w    = workerCounts(wi);
        mask = T.Max_Workers == w;
        Tw   = T(mask, :);

        % Sort by megapixels so the line goes left → right
        [~, si] = sort(Tw.Megapixels);
        Tw = Tw(si, :);

        hLines(wi) = plot(Tw.Megapixels, Tw.Speedup, ...
            '-o', ...
            'Color',           cmap(wi, :), ...
            'LineWidth',       1.8, ...
            'MarkerFaceColor', cmap(wi, :), ...
            'MarkerSize',      6);
    end

    xlabel('Image Size (Megapixels)', 'FontSize', 12);
    ylabel('Speedup',                 'FontSize', 12);
    title(sprintf('%s – Speedup vs Resolution', fileTitle), 'FontSize', 14);
    legend(hLines, arrayfun(@(w) sprintf('%d Workers', w), ...
           workerCounts, 'UniformOutput', false), ...
           'Location', 'northwest', 'FontSize', 10);
    grid on;
    set(gca, 'FontSize', 11, 'XScale', 'log');

    % Annotate x-axis with resolution names at each data point
    % (use the largest worker group to get the full set of x positions)
    maskRef = T.Max_Workers == workerCounts(end);
    Tref    = T(maskRef, :);
    [~, si] = sort(Tref.Megapixels);
    Tref    = Tref(si, :);
    set(gca, 'XTick', Tref.Megapixels, ...
             'XTickLabel', cellstr(Tref.Name), ...
             'XTickLabelRotation', 30);

    hold off;

    %% ── 4. Figure 2 – Speedup vs Worker Count (one line per resolution) ───
    figure('Name', 'Speedup vs Worker Count', 'NumberTitle', 'off', ...
           'Position', [180 180 860 520]);

    nRes   = numel(resNames);
    cmap2  = parula(nRes);
    hold on;
    hRes   = gobjects(nRes, 1);

    for ri = 1:nRes
        mask = T.Name == resNames(ri);
        Tr   = T(mask, :);
        [~, si] = sort(Tr.Max_Workers);
        Tr   = Tr(si, :);

        hRes(ri) = plot(Tr.Max_Workers, Tr.Speedup, ...
            '-s', ...
            'Color',           cmap2(ri, :), ...
            'LineWidth',       1.8, ...
            'MarkerFaceColor', cmap2(ri, :), ...
            'MarkerSize',      6);
    end

    xlabel('Number of Workers', 'FontSize', 12);
    ylabel('Speedup',           'FontSize', 12);
    title(sprintf('%s – Speedup vs Worker Count', fileTitle), 'FontSize', 14);
    legend(hRes, cellstr(resNames), ...
           'Location', 'northwest', 'FontSize', 9, 'NumColumns', 2);
    grid on;
    set(gca, 'FontSize', 11, ...
             'XTick',      workerCounts, ...
             'XTickLabel', arrayfun(@num2str, workerCounts, 'UniformOutput', false));
    xlim([workerCounts(1)-0.3, workerCounts(end)+0.3]);

    hold off;

    %% ── 5. Figure 3 – Efficiency (Speedup / Workers) heat-map ────────────
    % Build matrix:  rows = resolutions (MP order), cols = worker counts
    effMatrix = nan(nRes, numel(workerCounts));
    for ri = 1:nRes
        for wi = 1:numel(workerCounts)
            mask = T.Name == resNames(ri) & T.Max_Workers == workerCounts(wi);
            if any(mask)
                effMatrix(ri, wi) = T.Speedup(mask) / workerCounts(wi);
            end
        end
    end

    figure('Name', 'Parallel Efficiency Heat-map', 'NumberTitle', 'off', ...
           'Position', [260 260 700 460]);

    imagesc(effMatrix);
    colormap(hot);
    cb = colorbar;
    cb.Label.String = 'Efficiency  (Speedup / Workers)';
    cb.Label.FontSize = 11;
    clim([0 1]);

    set(gca, 'XTick', 1:numel(workerCounts), ...
             'XTickLabel', arrayfun(@(w) sprintf('%d', w), workerCounts, ...
                                    'UniformOutput', false), ...
             'YTick', 1:nRes, ...
             'YTickLabel', cellstr(resNames), ...
             'FontSize', 11);
    xlabel('Number of Workers', 'FontSize', 12);
    ylabel('Resolution',        'FontSize', 12);
    title(sprintf('%s – Parallel Efficiency', fileTitle), 'FontSize', 14);

    % Annotate each cell
    for ri = 1:nRes
        for wi = 1:numel(workerCounts)
            if ~isnan(effMatrix(ri, wi))
                text(wi, ri, sprintf('%.2f', effMatrix(ri, wi)), ...
                     'HorizontalAlignment', 'center', ...
                     'VerticalAlignment',   'middle', ...
                     'FontSize',            9, ...
                     'Color',               'cyan');
            end
        end
    end

end