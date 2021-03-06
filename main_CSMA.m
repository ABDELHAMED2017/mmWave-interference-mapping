clc; clear all;

addpath('geogridLib')
emulateSetup;
APinfo = [[-2.7980    1.5053    1    pi/2    5.7952];
[0.8270   -3.4125    1    pi/2    2.0921];
[2.32    2.27    1    pi/2    4.0054]];
bw = 90;
H = mean(APinfo(:, 3));
s = [Sender(APinfo(1, 1:3), rad2deg(APinfo(1, 4)), mod(rad2deg(APinfo(1, 5)), 360), bw, 'Sender 1'), ...
	  Sender(APinfo(2, 1:3), rad2deg(APinfo(2, 4)), mod(rad2deg(APinfo(2, 5)), 360), bw, 'Sender 2'), ...
	  Sender(APinfo(3, 1:3), rad2deg(APinfo(3, 4)), mod(rad2deg(APinfo(3, 5)), 360), bw, 'Sender 3')];
% f = figure(1); clf(f)
% EnvDeclare;
% s.plot(1, [Sender.pArray Sender.pBeam]);

%%%%%%%%%%%
BeamThetaS = zeros(3, 2);
BeamThetaR = zeros(3, 2);
BeamPhiS = zeros(3, 2);
BeamPhiR = zeros(3, 2);
r = [];
measureTH = [];
measureAssign = [];
measureActiveTime = [];
sendTurn = 1;
while true
    d1 = getlocate(1);
    d2 = getlocate(3);
    if isempty(d1) || isempty(d2)
        break;
    end
    d = [d1; d2];
    
    if isempty(r)
    r = [Receiver([d(1, 1:2) H], 90, mod(d(1, 4), 360), bw, 'Headset1'), ...
         Receiver([d(2, 1:2) H], 90, mod(d(2, 4), 360), bw, 'Headset2')];
    else
        r(1).setParams([d(1, 1:2) H], 90, mod(d(1, 4), 360));
        r(2).setParams([d(2, 1:2) H], 90, mod(d(2, 4), 360));
    end
 %r.plot(1, [Receiver.pArray Receiver.pBeam]);
    for si = 1:3
        for ri = 1:2
        [BeamThetaS(si, ri), BeamThetaR(si, ri)] = Radio.getBeamTheta(s(si), r(ri));
        [BeamPhiS(si, ri), BeamPhiR(si, ri)] = Radio.getBeamPhi(s(si), r(ri));
        end
    end
    LOS = ((BeamThetaS < deg2rad(bw)) & (BeamThetaR < deg2rad(bw)));
    
    trueAng = rad2deg(sign(BeamPhiS-pi).*BeamThetaS);
    for ri = 1:2
        for si = 1:3
            if ~LOS(si, ri)
                RSS{ri}(si, :) = getPattern(180, 1);
            else
                dist = sqrt(sum((APinfo(si, 1:3) - d(ri, 1:3)).^2));
                RSS{ri}(si, :) = getPattern(trueAng(si, ri), dist);
            end
        end
    end
    
    assign = assignAP(LOS);
    
    assign = assign(sendTurn);    
    RSS_{1} = RSS{sendTurn};
    RSS = RSS_;
    
    SIR = getSIR(RSS, assign, []);
    MCS = maptoMCS(SIR);
    th = getTH(MCS, assign);
    
    measureTH(end+1, sendTurn) = th;
    measureAssign(end+1, sendTurn) = assign;
    measureActiveTime(end+1, sendTurn) = 1;
    if sendTurn == 1
        sendTurn = 2;
    else
        sendTurn = 1;
    end
    %input('');
    
end
%%%%%%%%%%%

method = 'CSMA';
analyze;

