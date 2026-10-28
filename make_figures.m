%% make_figures.m  -  Todas las figuras de "Experiment 1: Tuning beta and FLOOR"
%
% Ejecutar desde la carpeta del proyecto (donde estan los resultados).
% Necesita:
%   tuning_ss_basic.mat    (lo crea tune_ss_basic.m)
%   results_ss_basic.mat   (lo crea final_ss_basic.m)
%   audios_ss_basic/       (lo crea final_ss_basic.m)
%
% Guarda todas las figuras en la carpeta  figures/  como PNG (300 dpi):
%   fig1_tuning_pesq.png       barrido de beta y FLOOR (PESQ)
%   fig2_tuning_ovl.png        barrido de beta y FLOOR (OVL)
%   fig3_results_pesq.png      original vs tuned (PESQ)
%   fig4_results_ovl.png       original vs tuned (OVL)
%   fig5_change_sig_bak.png    cuanto cambian SIG (voz) y BAK (ruido)
%   fig6_spectrograms_4.png    ruidosa / original / tuned / extremo
%   fig7_spectrograms_2.png    original vs tuned

clear; close all;

%% ---------------- CONFIGURACION ----------------
outDir   = 'figures';
specCond = 'babble_0dB';      % condicion de los espectrogramas (p.ej. 'car_10dB')
frase    = 'sp01';

names   = {'Car 10 dB','Car 0 dB','Babble 10 dB','Babble 0 dB'};
cBlue   = [0.29 0.47 0.69];   % original / car
cOrange = [0.78 0.37 0.08];   % tuned / babble
cGreen  = [0.23 0.56 0.36];   % SIG
cPurple = [0.48 0.37 0.65];   % BAK
measNames = {'SegSNR (dB)','PESQ','SIG','BAK','OVL'};

if ~exist(outDir,'dir'), mkdir(outDir); end
set(0,'DefaultAxesFontSize',12);

%% ================= FIG 1-2: barrido de beta y FLOOR =================
if exist('tuning_ss_basic.mat','file')
    T = load('tuning_ss_basic.mat');
    col = [cBlue; cBlue; cOrange; cOrange];   % azul = car, naranja = babble
    sty = {'-','--','-','--'};                % continua = 10 dB, discontinua = 0 dB
    fijos = ~isnan(T.betas);
    figNames = {'', 'fig1_tuning_pesq', '', '', 'fig2_tuning_ovl'};

    for m = [2 5]
        f = figure('Color','w','Position',[100 100 1150 430]);

        % --- beta ---
        subplot(1,2,1); hold on; grid on; box off
        h = zeros(1,4);
        for c = 1:4
            h(c) = plot(T.betas(fijos), squeeze(T.Rb(c,m,fijos)), sty{c}, 'Color', col(c,:), ...
                        'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', col(c,:));
        end
        yl = ylim;
        plot([T.bestBeta T.bestBeta], yl, 'k:', 'LineWidth', 1.3); ylim(yl);
        text(T.bestBeta, yl(1)+0.06*diff(yl), sprintf('  best \\beta = %g', T.bestBeta), 'FontSize', 11);
        xlabel('\beta (over-subtraction)'); ylabel(measNames{m});
        title(sprintf('Step 1: sweep \\beta  (FLOOR = %g)', T.FLOOR_0));

        % --- FLOOR ---
        subplot(1,2,2); hold on; grid on; box off
        for c = 1:4
            plot(T.floors, squeeze(T.Rf(c,m,:)), sty{c}, 'Color', col(c,:), ...
                 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 6, 'MarkerFaceColor', col(c,:));
        end
        set(gca, 'XScale', 'log');
        yl = ylim;
        plot([T.bestFloor T.bestFloor], yl, 'k:', 'LineWidth', 1.3); ylim(yl);
        text(T.bestFloor, yl(1)+0.06*diff(yl), sprintf('  best FLOOR = %g', T.bestFloor), 'FontSize', 11);
        xlabel('FLOOR (log scale)'); ylabel(measNames{m});
        title(sprintf('Step 2: sweep FLOOR  (\\beta = %g)', T.bestBeta));
        legend(h, names, 'Location', 'southoutside', 'Orientation', 'horizontal');

        print(f, fullfile(outDir, [figNames{m} '.png']), '-dpng', '-r300');
    end
    fprintf('Fig 1-2 (tuning) hechas\n');
else
    warning('No encuentro tuning_ss_basic.mat: me salto las figuras 1-2');
end

%% ================= FIG 3-5: resultados finales =================
if exist('results_ss_basic.mat','file')
    R = load('results_ss_basic.mat');
    lblTuned = sprintf('Tuned (\\beta = %g, FLOOR = %g)', R.bestBeta, R.bestFloor);
    figNames = {'', 'fig3_results_pesq', '', '', 'fig4_results_ovl'};

    % --- Fig 3-4: original vs tuned ---
    for m = [2 5]
        Y = [R.R_orig(:,m) R.R_best(:,m)];
        f = figure('Color','w','Position',[100 100 900 450]);
        b = bar(Y, 0.8); hold on; grid on; box off
        set(b(1), 'FaceColor', cBlue,   'EdgeColor', 'none');
        set(b(2), 'FaceColor', cOrange, 'EdgeColor', 'none');
        for k = 1:2                                   % valores encima de las barras
            try, xk = b(k).XEndPoints; catch, xk = (1:4) + (k-1.5)*0.28; end   % centro de cada barra
            for i = 1:4
                text(xk(i), Y(i,k), sprintf('%.2f', Y(i,k)), 'HorizontalAlignment', 'center', ...
                     'VerticalAlignment', 'bottom', 'FontSize', 11);
            end
        end
        set(gca, 'XTick', 1:4, 'XTickLabel', names);
        ylim([0 max(Y(:))*1.35]);
        ylabel(measNames{m});
        title(sprintf('%s: original vs tuned (30 sentences)', measNames{m}));
        legend({'Original (Berouti, FLOOR = 0.002)', lblTuned}, 'Location', 'northeast');
        print(f, fullfile(outDir, [figNames{m} '.png']), '-dpng', '-r300');
    end

    % --- Fig 5: cambio de SIG (voz) y BAK (ruido de fondo) ---
    D = R.R_best(:,[3 4]) - R.R_orig(:,[3 4]);
    f = figure('Color','w','Position',[100 100 900 450]);
    b = bar(D, 0.8); hold on; grid on; box off
    set(b(1), 'FaceColor', cGreen,  'EdgeColor', 'none');
    set(b(2), 'FaceColor', cPurple, 'EdgeColor', 'none');
    for k = 1:2
        try, xk = b(k).XEndPoints; catch, xk = (1:4) + (k-1.5)*0.28; end   % centro de cada barra
        for i = 1:4
            if D(i,k) >= 0, va = 'bottom'; else, va = 'top'; end
            text(xk(i), D(i,k), sprintf('%+.2f', D(i,k)), 'HorizontalAlignment', 'center', ...
                 'VerticalAlignment', va, 'FontSize', 11);
        end
    end
    plot([0.5 4.5], [0 0], 'k-', 'LineWidth', 1);
    set(gca, 'XTick', 1:4, 'XTickLabel', names);
    ylim([min(0, min(D(:)))-0.08, max(D(:))*1.2]);
    ylabel('Change vs original');
    title('Tuned vs original: the voice improves much more than the noise');
    legend({'SIG (speech quality)', 'BAK (background noise)'}, 'Location', 'northwest');
    print(f, fullfile(outDir, 'fig5_change_sig_bak.png'), '-dpng', '-r300');
    fprintf('Fig 3-5 (resultados) hechas\n');
else
    warning('No encuentro results_ss_basic.mat: me salto las figuras 3-5');
end

%% ================= FIG 6-7: espectrogramas =================
base = fullfile('audios_ss_basic', sprintf('%s_%s_', frase, specCond));
files  = {'1_ruidosa', '2_original', '3_mejor', '4_extremo'};
titles = {'Noisy', 'Original SS', 'Tuned SS', 'Extreme (\beta = 6, FLOOR = 0.001)'};

if exist([base files{1} '.wav'], 'file')
    N = 256; H = 64; nfft = 512;                       % 32 ms, 75 % solape a 8 kHz
    w = 0.54 - 0.46*cos(2*pi*(0:N-1)'/(N-1));          % ventana de Hamming
    SP = cell(1,4);
    for i = 1:4
        [x, fs] = audioread([base files{i} '.wav']); x = x(:,1);
        nfr = floor((length(x)-N)/H) + 1;
        S = zeros(nfft/2+1, nfr);
        for k = 1:nfr
            X = fft(x((k-1)*H + (1:N)) .* w, nfft);
            S(:,k) = abs(X(1:nfft/2+1)).^2;
        end
        SP{i} = struct('S', 10*log10(S+1e-12), 't', ((0:nfr-1)*H + N/2)/fs, ...
                       'f', (0:nfft/2)*fs/nfft/1000);
    end
    top = max(SP{1}.S(:));                             % misma escala de color para todos
    cl  = [top-70, top];

    % --- Fig 6: los 4 ---
    f = figure('Color','w','Position',[100 100 1150 620]);
    for i = 1:4
        subplot(2,2,i);
        imagesc(SP{i}.t, SP{i}.f, SP{i}.S); axis xy; caxis(cl); colormap(hot);
        title(titles{i}); box off
        if i > 2, xlabel('Time (s)'); end
        if mod(i,2) == 1, ylabel('Frequency (kHz)'); end
    end
    print(f, fullfile(outDir, 'fig6_spectrograms_4.png'), '-dpng', '-r300');

    % --- Fig 7: original vs tuned ---
    f = figure('Color','w','Position',[100 100 1150 400]);
    for j = 1:2
        i = j + 1;
        subplot(1,2,j);
        imagesc(SP{i}.t, SP{i}.f, SP{i}.S); axis xy; caxis(cl); colormap(hot);
        title(titles{i}); xlabel('Time (s)'); box off
        if j == 1, ylabel('Frequency (kHz)'); end
    end
    print(f, fullfile(outDir, 'fig7_spectrograms_2.png'), '-dpng', '-r300');
    fprintf('Fig 6-7 (espectrogramas) hechas\n');
else
    warning('No encuentro %s*.wav: me salto los espectrogramas', base);
end

fprintf('\nListo. Figuras guardadas en la carpeta "%s"\n', outDir);