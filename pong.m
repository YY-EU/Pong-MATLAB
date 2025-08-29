% pong.m
% Simple Pong game in MATLAB
% Save as pong.m and run. Use W/S for left paddle, Up/Down for right paddle.
% R to restart, P to pause/unpause, Esc to quit.

function pong
    close all
    % Game parameters
    fieldW = 100; fieldH = 60;
    paddleW = 1.5; paddleH = 12;
    paddleSpeed = 60;          % units per second
    ballRadius = 1.2;
    ballSpeed = 55;            % initial speed units/sec
    maxScore = 7;

    % Game state
    state.leftY = fieldH/2;
    state.rightY = fieldH/2;
    state.leftVel = 0;
    state.rightVel = 0;
    state.ballPos = [fieldW/2, fieldH/2];
    ang = (rand*2-1)*pi/4 + (rand>0.5)*pi; % random angle
    state.ballVel = ballSpeed * [cos(ang), sin(ang)];
    state.running = true;
    state.paused = false;
    state.leftScore = 0;
    state.rightScore = 0;
    state.isAI = false; % change to true to let right paddle be AI

    % Input flags
    keys.w = false; keys.s = false; keys.up = false; keys.down = false;

    % Create figure and graphics
    fig = figure('Name','MATLAB Pong','NumberTitle','off','Color','k',...
        'MenuBar','none','ToolBar','none','KeyPressFcn',@keyDown,...
        'KeyReleaseFcn',@keyUp,'CloseRequestFcn',@onClose);
    ax = axes('Parent',fig,'XLim',[0 fieldW],'YLim',[0 fieldH],...
        'Color','k','XColor','none','YColor','none','Position',[0 0 1 1]);
    axis(ax,'manual'); hold(ax,'on');

    % Draw midline
    for y = 0:5:fieldH
        plot(ax,[fieldW/2 fieldW/2],[y y+2],'-','Color',[0.7 0.7 0.7]);
    end

    leftRect = rectangle(ax,'Position',[2, state.leftY - paddleH/2, paddleW, paddleH],...
        'FaceColor','w','EdgeColor','w','Curvature',0.1);
    rightRect = rectangle(ax,'Position',[fieldW-2-paddleW, state.rightY - paddleH/2, paddleW, paddleH],...
        'FaceColor','w','EdgeColor','w','Curvature',0.1);

    ball = rectangle(ax,'Position',[state.ballPos(1)-ballRadius, state.ballPos(2)-ballRadius, 2*ballRadius, 2*ballRadius],...
        'Curvature',[1 1],'FaceColor','w','EdgeColor','w');

    scoreText = text(ax, fieldW/2, fieldH-4, scoreStr(), 'HorizontalAlignment','center',...
        'FontSize',14,'Color','w','FontWeight','bold');

    info = text(ax, 5, fieldH-4, 'W/S: left | Up/Down: right | P: pause | R: restart | Esc: quit', ...
        'HorizontalAlignment','left','FontSize',9,'Color',[0.8 0.8 0.8]);

    % Game loop
    prevT = tic;
    while ishandle(fig) && state.running
        dt = toc(prevT); prevT = tic;
        if state.paused
            drawnow limitrate
            pause(0.02)
            continue
        end

        % Update paddles from input
        state.leftVel = 0;
        if keys.w; state.leftVel = paddleSpeed; end
        if keys.s; state.leftVel = -paddleSpeed; end

        if state.isAI
            % simple AI: follow ball with some max speed
            if state.ballPos(2) > state.rightY + 2
                state.rightVel = paddleSpeed*0.95;
            elseif state.ballPos(2) < state.rightY - 2
                state.rightVel = -paddleSpeed*0.95;
            else
                state.rightVel = 0;
            end
        else
            state.rightVel = 0;
            if keys.up; state.rightVel = paddleSpeed; end
            if keys.down; state.rightVel = -paddleSpeed; end
        end

        % Move paddles
        state.leftY = state.leftY + state.leftVel * dt;
        state.rightY = state.rightY + state.rightVel * dt;
        % clamp
        halfH = paddleH/2;
        state.leftY = min(max(state.leftY, halfH), fieldH-halfH);
        state.rightY = min(max(state.rightY, halfH), fieldH-halfH);

        % Move ball
        state.ballPos = state.ballPos + state.ballVel * dt;

        % Collisions with top/bottom walls
        if state.ballPos(2) + ballRadius >= fieldH
            state.ballPos(2) = fieldH - ballRadius;
            state.ballVel(2) = -abs(state.ballVel(2));
        elseif state.ballPos(2) - ballRadius <= 0
            state.ballPos(2) = ballRadius;
            state.ballVel(2) = abs(state.ballVel(2));
        end

        % Paddle collisions
        % Left paddle hit area
        leftX = 2 + paddleW; % right face of left paddle
        if state.ballPos(1) - ballRadius <= leftX
            % check if vertically overlaps
            if abs(state.ballPos(2) - state.leftY) <= (paddleH/2 + 0.5)
                % reflect, adjust angle depending on hit position
                offset = (state.ballPos(2) - state.leftY) / (paddleH/2); % -1..1
                bounceAngle = offset * (pi/3); % +/-60 degrees
                dir = +1; % send right
                speed = norm(state.ballVel) * 1.03; % slight speed up
                speed = min(speed, 250);
                state.ballVel = speed * [cos(bounceAngle)*dir, sin(bounceAngle)];
                state.ballPos(1) = leftX + ballRadius + 0.1;
            end
        end

        % Right paddle
        rightX = fieldW-2-paddleW; % left face of right paddle
        if state.ballPos(1) + ballRadius >= rightX
            if abs(state.ballPos(2) - state.rightY) <= (paddleH/2 + 0.5)
                offset = (state.ballPos(2) - state.rightY) / (paddleH/2);
                bounceAngle = offset * (pi/3);
                dir = -1; % send left
                speed = norm(state.ballVel) * 1.03;
                speed = min(speed, 250);
                state.ballVel = speed * [cos(pi + bounceAngle)*-1, sin(pi + bounceAngle)]; % alternative robust reflection
                % simpler:
                state.ballVel = speed * [-cos(bounceAngle), sin(bounceAngle)];
                state.ballPos(1) = rightX - ballRadius - 0.1;
            end
        end

        % Score if ball goes beyond paddles
        if state.ballPos(1) < 0
            state.rightScore = state.rightScore + 1;
            if state.rightScore >= maxScore
                winner = 'Right Player Wins!';
                showWinner(winner);
                break
            end
            resetBall(-1);
        elseif state.ballPos(1) > fieldW
            state.leftScore = state.leftScore + 1;
            if state.leftScore >= maxScore
                winner = 'Left Player Wins!';
                showWinner(winner);
                break
            end
            resetBall(1);
        end

        % Update graphics
        set(leftRect,'Position',[2, state.leftY - paddleH/2, paddleW, paddleH]);
        set(rightRect,'Position',[fieldW-2-paddleW, state.rightY - paddleH/2, paddleW, paddleH]);
        set(ball,'Position',[state.ballPos(1)-ballRadius, state.ballPos(2)-ballRadius, 2*ballRadius, 2*ballRadius]);
        set(scoreText,'String',scoreStr());
        drawnow limitrate

        pause(0.005) % small sleep to reduce CPU
    end

    function s = scoreStr()
        s = sprintf('%d     %d', state.leftScore, state.rightScore);
    end

    function resetBall(direction)
        % direction = +1 send to right (last scored left), -1 send to left
        state.ballPos = [fieldW/2, fieldH/2];
        ang = ((rand*2-1)*pi/4); % -45..45 deg
        state.ballVel = direction * ballSpeed * [cos(ang), sin(ang)];
    end

    function keyDown(~,ev)
        switch lower(ev.Key)
            case 'w'
                keys.w = true;
            case 's'
                keys.s = true;
            case 'uparrow'
                keys.up = true;
            case 'downarrow'
                keys.down = true;
            case 'p' % pause
                state.paused = ~state.paused;
            case 'r' % restart
                state.leftScore = 0; state.rightScore = 0;
                state.leftY = fieldH/2; state.rightY = fieldH/2;
                resetBall(1);
                state.paused = false;
            case 'escape'
                cleanupAndClose();
            case 'a' % toggle AI for right paddle
                state.isAI = ~state.isAI;
                if state.isAI
                    info.String = [info.String ' | AI: ON'];
                else
                    info.String = 'W/S: left | Up/Down: right | P: pause | R: restart | Esc: quit';
                end
        end
    end

    function keyUp(~,ev)
        switch lower(ev.Key)
            case 'w'
                keys.w = false;
            case 's'
                keys.s = false;
            case 'uparrow'
                keys.up = false;
            case 'downarrow'
                keys.down = false;
        end
    end

    function onClose(~,~)
        cleanupAndClose();
    end

    function cleanupAndClose()
        state.running = false;
        if ishandle(fig)
            delete(fig)
        end
    end

    function showWinner(msg)
        state.paused = true;
        if ishandle(ax)
            t = text(ax, fieldW/2, fieldH/2, msg, 'HorizontalAlignment','center',...
                'FontSize',20,'Color','y','FontWeight','bold');
        end
        pause(2.0)
        cleanupAndClose();
    end
end
