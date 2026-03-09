% =========================================================================
% Practical 2: Mandelbrot-Set Serial vs Parallel Analysis
% =========================================================================
%
% GROUP NUMBER:
%
% MEMBERS:
%   - Glen Jones, JNSGLE007
%   - Michael Lighton, LGHMIC003

%% ========================================================================
%  PART 4: Testing and Analysis
%  ========================================================================
% Compare the performance of serial Mandelbrot set computation
% with parallel Mandelbrot set computation.

function run_analysis()
    fprintf("========================= Setting up run_analysis ========================= \n")
    %Array conatining all the image sizes to be tested
    image_sizes = [
        [800,600],   %SVGA
        [1280,720],  %HD
        [1920,1080], %Full HD
        [2048,1080], %2K Cinema
        [2560,1440], %2K QHD
        [3840,2160], %4K UHD
        [5120,2880], %5K
        [7680,4320]  %8K UHD
    ];
    image_names =  {'SVGA','HD','Full HD','2K','QHD','4K UHD','5K','8K UHD'};
    num_images = size(image_sizes, 1);
    max_iterations = 1000;

    % Allocating results:
    time_serial   = zeros(num_images, 1);
    time_parallel = zeros(num_images, 1);
    
    % Starting pool outised of the timing
    fprintf("========================= Starting worker pool ========================= \n")
    max_workers = feature('numcores');
    fprintf('Number of cores (Max workers): %d\n', max_workers);
    % Manual ovveride for testing:
    num_workers = 3;
    pool = gcp('nocreate');
    if isempty(pool)
        parpool('local', num_workers);  % uses default number of workers
    end

    % Setting up CSV folder: 
    csv_file = 'results/benchmark_results.csv';
    
    % ensure results folder exists
    if ~exist('results','dir')
        mkdir('results');
    end
    
    % create file only if it doesn't exist
    if ~exist(csv_file,'file')
        fid = fopen(csv_file,'w');
        fprintf(fid,'Name,Width,Height,Megapixels,Max_Workers,T_Serial,T_Parallel,Speedup\n');
        fclose(fid);
    end

    % TODO: ALSO ITERATE THROUGH MAX_WORKERS FOR PARALLEL
    fid = fopen(csv_file,'a');
    if fid == -1
        fprintf("Error in opening CSV file")
    end


    % ITERATING OVER WORKER COUNT
    for workers = 2:max_workers
        fprintf('Creating parallel pool with %s workers' , workers)

        % Creating new pool
        pool = gcp('nocreate');
            if isempty(pool) || pool.NumWorkers ~= workers
                if ~isempty(pool)
                    delete(pool);
                end
                parpool('local', workers);
            end
      
    % ITERATING THROUGH IMAGES        

        for r=1:num_images
            % TODO: ADD COMMENT
            width = image_sizes(r, 1);
            height = image_sizes(r, 2);
            fprintf('\n--- %s (%dx%d) ---\n', image_names{r}, width, height);
        
        %TODO: For each image size, perform the following:
        %   a. Measure execution time of mandelbrot_serial
    
    
        % ---- Serial timing ----
        for i = 1:3% Iterating multiple runs to find colosest to theoretical max
            fprintf('Serial run number %d \n', i);
            t_start = tic;
            img_serial = mandelbrot_serial(width, height, max_iterations);
            time_stop = toc(t_start);
            time_serial_for_loop(i) = time_stop;
            %time_serial(r) = toc(t_start);
           
        end
        % Taking minumum of the runs:
        time_serial(r) = min(time_serial_for_loop);
         fprintf('Fastest serial time %.3f s\n', time_serial(r));
        %   b. Measure execution time of mandelbrot_parallel
    

            % ---- Parallel timing ----
        for i = 1:3% Iterating multiple runs to find colosest to theoretical max
             fprintf('Parallel run number %d \n', i);
            t_start = tic;
            img_parallel = mandelbrot_parallel(width, height, max_iterations);
            time_stop = toc(t_start);
            time_parallel_for_loop(i) = time_stop;
        end
        time_parallel(r) = min(time_parallel_for_loop(i));
        fprintf('Fastest Parallel Time %.3f s\n', time_parallel(r));
    
        % TODO: VERIFICATION
        % Comparing Serial and Parallel implementatons:
        
        % Maximum difference between serial and parrallel
         difference = max(abs(double(img_serial(:)) - double(img_parallel(:))));
         if difference ~= 0
             fprintf('ERROR: Serial and Parallel do not match.\n');
         else
             fprintf("PASS: Serial and parallel images match. \n")
         end
             
    
        %   c. Store results (image size, time_serial, time_parallel, speedup)  
    
        speedup = time_serial(r) / time_parallel(r);

        fprintf('Speed up: %.2f \n', speedup);

        megapx = (width * height) / 1e6;
        % Writing to CSV
        fprintf(fid, '%s,%d,%d,%.4f,%d,%.4f,%.4f,%.4f\n', ...
            image_names{r}, width, height, megapx, workers, ...
            time_serial(r), time_parallel(r), speedup);
     

        % Printing to console:
        fprintf('%-20s %-10d %-10d %-10.2f %-10d %-12.4f %-12.4f %-12.4f\n', ...
            image_names{r}, width, height, megapx, workers, ...
            time_serial(r), time_parallel(r), speedup);
            
        %   d. Plot and save the Mandelbrot set images generated by both
        %   methods
        % TODO: Fix image storage
        mandelbrot_plot(img_serial,   sprintf('serial_%s.png',   image_names{r}), sprintf('Serial - %s',   image_names{r}));
        mandelbrot_plot(img_parallel, sprintf('parallel_%s.png', image_names{r}), sprintf('Parallel - %s', image_names{r}));
        end

    end

    fclose(fid);


end

%% ========================================================================
%  PART 1: Mandelbrot Set Image Plotting and Saving
%  ========================================================================
%
% TODO: Implement Mandelbrot set plotting m  and saving function
function mandelbrot_plot(image_data, filename, title_str)
    % Create the output directory for images
    if ~exist('results/images', 'dir')
        mkdir('results/images');
    end
    filepath = fullfile('results', 'images', filename);
    % TODO: add comments so it doesnt look like GPT cooked here lol
    img_normalised = mat2gray(double(image_data));
    img_rgb        = ind2rgb(im2uint8(img_normalised), hot(256));
    imwrite(img_rgb, filepath);
    fprintf('Saved: %s (%dx%d)\n', filepath, size(image_data,2), size(image_data,1));
end

%% ========================================================================
%  PART 2: Serial Mandelbrot Set Computation
%  ========================================================================`
%
%TODO: Implement serial Mandelbrot set computation function
function image_data = mandelbrot_serial(width, height, max_iter) %Add necessary input arguments 
       
    x_coordinates = linspace(-2.0 , 0.5, width);
    y_coordinates = linspace(-1.5, 1.5, height);
    image_data = zeros(height,width,'uint16');% Output Matrix
       
    % Iterating over y (Imag axis)
    for row = 1:height 
        y0 = y_coordinates(row);

        % Iterating over col (real axis)
        for col = 1:width
            x0 = x_coordinates(col);
            x   = 0.0;
            y   = 0.0;
            iter = 0;

            % Escape condition: x^2 + y^2 > 4  (i.e. |z| > 2)
            % Run Mandelbrot iterationsfor single pixel
            while (iter < max_iter) && (x*x + y*y <= 4.0)
                x_next = x*x - y*y + x0;
                y_next = 2.0*x*y  + y0;
                x      = x_next;
                y      = y_next;
                iter   = iter + 1;
            end

            image_data(row, col) = uint16(iter);
        end
    end

  
end

%% ========================================================================
%  PART 3: Parallel Mandelbrot Set Computation
%  ========================================================================
%
%TODO: Implement parallel Mandelbrot set computation function
function image_data = mandelbrot_parallel(width, height, max_iter) 
    x_coordinates = linspace(-2.0 , 0.5, width);
    y_coordinates = linspace(-1.5, 1.5, height);
    image_data = zeros(height,width,'uint16');%  Preallocate Output Matrix
       
    % Iterating over y (Imag axis)
    parfor row = 1:height 
        % Each parfor ges own row
        y0 = y_coordinates(row);
         row_worker_result = zeros(1,width,'uint16'); % temporary row

        % Iterating over col (real axis)
        for col = 1:width
            x0 = x_coordinates(col); % NB READ ONLY SO DOES NOT PRODUCE MEMORY CONFLICS even tho broadcast var
            x   = 0.0; 
            y   = 0.0;
            iter = 0;

            % Escape condition: x^2 + y^2 > 4  (i.e. |z| > 2)
            % Run Mandelbrot iterationsfor single pixel
            while (iter < max_iter) && (x*x + y*y <= 4.0)
                x_next = x*x - y*y + x0;
                y_next = 2.0*x*y  + y0;
                x      = x_next;
                y      = y_next;
                iter   = iter + 1;
            end
            
            %Sliced variable
            row_worker_result(col) = uint16(iter);
        end

        image_data(row,:) = row_worker_result;
    end
end


