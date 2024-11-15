classdef MotionTracker < handle
    properties
        vid         % Video input object
        fig         % Figure handle
        axes        % Axes handle
        background  % Background frame
        isRunning   % Flag to control tracking
    end
    
    methods
        function obj = MotionTracker()
            try
                % Initialize video
                obj.vid = videoinput('winvideo', 1);
                
                % Configure video
                obj.vid.FramesPerTrigger = 1;
                obj.vid.TriggerRepeat = Inf;
                
                % Create figure window
                obj.fig = figure('Name', 'Motion Tracker', ...
                               'NumberTitle', 'off', ...
                               'Position', [100 100 800 600]);
                
                % Create axes
                obj.axes = axes('Parent', obj.fig);
                
                % Add buttons
                uicontrol('Style', 'pushbutton', ...
                         'String', 'Start', ...
                         'Position', [20 20 60 30], ...
                         'Callback', @(~,~)obj.startTracking());
                     
                uicontrol('Style', 'pushbutton', ...
                         'String', 'Stop', ...
                         'Position', [90 20 60 30], ...
                         'Callback', @(~,~)obj.stopTracking());
                
                % Preview video
                preview(obj.vid);
                
                disp('Motion Tracker initialized!');
                
            catch ME
                errordlg(['Init error: ' ME.message]);
            end
        end
        
        function startTracking(obj)
            try
                % Stop preview
                stoppreview(obj.vid);
                
                % Start video
                start(obj.vid);
                
                % Get background
                obj.background = getsnapshot(obj.vid);
                
                while isrunning(obj.vid)
                    % Get frame
                    frame = getsnapshot(obj.vid);
                    
                    % Process frame
                    obj.processFrame(frame);
                    
                    % Update display
                    drawnow;
                end
                
            catch ME
                errordlg(['Tracking error: ' ME.message]);
                obj.stopTracking();
            end
        end
        
        function processFrame(obj, frame)
            % Convert frames
            current = im2double(frame);
            back = im2double(obj.background);
            
            % Calculate difference
            diff_frame = abs(current - back);
            
            % Convert to grayscale
            if size(diff_frame, 3) > 1
                diff_frame = rgb2gray(diff_frame);
            end
            
            % Threshold
            motion_mask = diff_frame > 0.15;
            
            % Clean up noise
            motion_mask = bwareaopen(motion_mask, 50);
            motion_mask = imclose(motion_mask, strel('disk', 7));
            
            % Find motion regions
            stats = regionprops(motion_mask, 'Centroid', 'BoundingBox', 'Area');
            
            % Display frame
            imshow(frame, 'Parent', obj.axes);
            hold(obj.axes, 'on');
            
            % Draw detections
            for i = 1:length(stats)
                if stats(i).Area > 1000
                    % Draw box
                    rectangle('Position', stats(i).BoundingBox, ...
                             'EdgeColor', 'r', ...
                             'LineWidth', 2);
                    
                    % Draw center point
                    plot(stats(i).Centroid(1), stats(i).Centroid(2), ...
                         'g*', 'MarkerSize', 20);
                end
            end
            
            hold(obj.axes, 'off');
            
            % Update background
            obj.background = uint8(0.95 * double(obj.background) + 0.05 * double(frame));
        end
        
        function stopTracking(obj)
            try
                stop(obj.vid);
                preview(obj.vid);  % Restart preview
            catch
                % Handle errors
            end
        end
        
        function delete(obj)
            try
                stoppreview(obj.vid);
                stop(obj.vid);
                delete(obj.vid);
            catch
                % Handle cleanup errors
            end
        end
    end
end