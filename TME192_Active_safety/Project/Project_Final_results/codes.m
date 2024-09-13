%% Task 1
%% a)1. A hypothetical rear-end conflict situation 
v_sta = 25;
a_sta = -5;
v_lead = 0;
t_rt = 1.5;
x_min = (v_lead^2 - v_sta^2)/(2*a_sta);

%% b)
ttc =x_min/v_sta;

%% c)
x_new = 90;
x_thr = v_sta*t_rt + (v_lead^2 - v_sta^2)/(2*a_sta);

%% d)
initial_velocity_A = 25;  
deceleration_A = -5;      
distance_to_B = 90;       
time_step = 0.01;          
current_time = 0;         

position_A = 0;
position_B = distance_to_B;
TTC = 90/25;
x_dash = [0:0.1:1];
y_dash = 0.5;

figure;

while true
    
    current_time = current_time + time_step;
    
    if current_time <= 1.5
        velocity_A =  initial_velocity_A;
        position_A = position_A + initial_velocity_A * time_step;
        
    else
        velocity_A = velocity_A + deceleration_A * time_step;
        position_A = position_A + (velocity_A-deceleration_A*time_step+velocity_A)*0.5*time_step;
        
    end 
    
    if position_A > (position_B  + 0.05)
        break;
    end
    
    clf;
    hold on;
    fill([0,100,100,0],[-1,-1,2,2],[0.5, 0.5, 0.5]);
    line([0,100],[0.5,0.5],'linestyle','--','color','w','linewidth',2);
    plot(position_A, 0, 'ro-', 'MarkerSize', 5,'MarkerFaceColor','r'); 
    plot(position_B, 0, 'bo-', 'MarkerSize', 5','MarkerFaceColor','b'); 
    txt = ["time = "+roundn(current_time,-1)+'s',"distance driven = "+roundn(position_A,-1)+"m", "distance to obstacle = "+roundn((90 - position_A),-1)+"m","TTC = "+roundn((90-position_A)/velocity_A,-1)+"s"];
    text(10,-3,txt);
    xlim([0, distance_to_B + 10]); 
    ylim([-5, 5]); 
    title('Active Safety Project: Rear-end scenario');
    legend('','','Car A', 'Car B');
    grid on;
    

    drawnow;
    
    
     %pause(0.1);
end



pause;


close;
%% Task 2
clc; clear;close all;
load("RadarData.mat");
%Create a new structure
fields = {'RadarRange','RadarRangeRate','RadarAccel','VehicleSpeed','VehicleYawRate','TestPerson','RadarTime','VehicleTime','FileName'};
new_data = struct([]);

index_new = 1;
for i = 1:length(RadarData)
    if ~all(isnan(RadarData(i).RadarRange)) %Remove only NaNs in the radar range data)
        new_data(index_new).RadarRange = RadarData(i).RadarRange;
        new_data(index_new).RadarRangeRate = RadarData(i).RadarRangeRate;
        new_data(index_new).RadarAccel = RadarData(i).RadarAccel;
        new_data(index_new).VehicleSpeed = RadarData(i).VehicleSpeed;
        new_data(index_new).VehicleYawRate = RadarData(i).VehicleYawRate;
        new_data(index_new).TestPerson = RadarData(i).TestPerson;
        new_data(index_new).RadarTime = RadarData(i).RadarTime-0.2;%Synchronize the radar and vehicle kinematics time
        new_data(index_new).VehicleTime = RadarData(i).VehicleTime;
        new_data(index_new).FileName = RadarData(i).FileName;

        index_new = index_new + 1;
    end
end
%% Integral range
for i = 1:length(new_data)
    for j = 1:length(new_data)             
        new_data(j).RadarRangeIntegral = cumtrapz(new_data(j).VehicleTime,-(new_data(j).VehicleSpeed)); % integrating speed to get range
        new_data(j).offset = new_data(j).RadarRangeIntegral(1:length(new_data(j).RadarRange))-new_data(j).RadarRange; % find offset
        new_data(j).RadarRange_re = new_data(j).RadarRangeIntegral- mean(new_data(j).offset(~isnan(new_data(j).offset))); % offest by mean value to match original data
    end
end


%% Create the structure that saves the results /changed
results = struct('Participant',[], 'Meanacceleration', [],'Minimumacceleration',[], ...
                 'Speedatbrakeonset', [],'Rangeatbrakeonset', [], ...
                   'TTCatbrakeonset', []);

for i = 1:length(new_data)
    
    acc = [];
    %Calculate acceleration a = delta V / delta T
    for j = 2:length(new_data(i).VehicleSpeed)
        acc(j-1) = (new_data(i).VehicleSpeed(j)-new_data(i).VehicleSpeed(j-1))/(new_data(i).VehicleTime(j)-new_data(i).VehicleTime(j-1));
    end
    if isempty(find(acc < -1.4)) == 0 %Restricte brake conditions
        new_data(i).Brake = 1;        %According to the acceleration limit braking conditions, 
                                      %when there is a brake assigned to 1, and otherwise assigned to 0
    else
        new_data(i).Brake = 0;
    end
    if new_data(i).Brake ==1
        start_i = find(acc < -1.4, 1); %Find the braking process and record brake start time
        end_i1 = find(acc < 0);
        end_i2 = find(new_data(i).VehicleSpeed < 0.3);
        end_i3 = intersect(end_i2,end_i1);
        end_i4 = find(end_i3 > start_i); %Find the end time of braking, when the acceleration is less than 0 and the speed is less than 0.3
        if ~all(isnan(end_i4)) && ~any(isnan(new_data(i).RadarRange(start_i))) %Filter out some data based on radar range data
            figure(i)
            end_i = end_i3(end_i4(1));
            avg_acceleration = (new_data(i).VehicleSpeed(end_i) - new_data(i).VehicleSpeed(start_i))/(new_data(i).VehicleTime(end_i) - new_data(i).VehicleTime(start_i));%Calculate the average acceleration a = V2-V1 / T2-T1
            min_acceleration = min(acc(start_i:end_i));%Calculate the minimum acceleration
            results(i).Participant = new_data(i).TestPerson;
            results(i).Meanacceleration = avg_acceleration;
            results(i).Minimumacceleration = min_acceleration;
            results(i).Speedatbrakeonset = new_data(i).VehicleSpeed(start_i);
            results(i).Rangeatbrakeonset = new_data(i).RadarRange(start_i);      
            results(i).TTCatbrakeonset = results(i).Rangeatbrakeonset/new_data(i).VehicleSpeed(start_i);

            plot(new_data(i).VehicleTime,new_data(i).VehicleSpeed);
            % plot(new_data(i).RadarTime,new_data(i).RadarRange)
            xline(new_data(i).VehicleTime(start_i),'--');
            xline(new_data(i).VehicleTime(end_i),'--');
            xlabel('Time[s]')
            ylabel('V [m/s]')
        else %Remove the case where start point of the radar range data is an empty set
            avg_acceleration = [];
            min_acceleration = [];
            results(i).Participant = new_data(i).TestPerson;
            results(i).Meanacceleration = avg_acceleration;
            results(i).Minimumacceleration = min_acceleration;
            results(i).Speedatbrakeonset = [];
            results(i).Rangeatbrakeonset = [];       
            results(i).TTCatbrakeonset = [];
        end
        
       
    end
end
results_table = struct2table(results);
table_test = table2array(results_table);
%By viewing the images, the three sets of data which did not meet the requirements were removed manually (39, 27,20)
remove_row_test = [39, 27, 20];
table_test(remove_row_test, :) = [];
%Remove data with NaN values
[num_rows, ~] = size(table_test);
empty_rows = [];
for i = 1:num_rows
    value = table_test{i, 2};
    
    if isempty(value)
        empty_rows = [empty_rows, i];
    end
end

table_test(empty_rows, :) = [];
table_test = array2table(table_test);

old_table_test_name = {'table_test1','table_test2','table_test3','table_test4','table_test5','table_test6'};
new_table_test_name = {'Participant', 'Mean acceleration [m/s^2]','Minimum acceleration [m/s^2]', ...
                                          'Speed at brakeonset [m/s]','Range at brake onset [m]', ...
                                            'TTC at brake onset [s]'};
table_test = renamevars(table_test,old_table_test_name,new_table_test_name);



%% Plot
plot(new_data(6).VehicleTime(10:106),new_data(6).VehicleSpeed(10:106),'LineWidth',1);
hold on;
plot(new_data(6).VehicleTime(10:106),new_data(6).VehicleYawRate(10:106),'LineWidth',1);
hold on;
plot(new_data(6).RadarTime(10:106),new_data(6).RadarRange(10:106),'LineWidth',1);
hold on;
plot(new_data(6).RadarTime(10:106),-new_data(6).RadarRangeRate(10:106),'LineWidth',1);
hold on;
plot(new_data(6).VehicleTime(10:106),new_data(6).RadarRange_re(10:106),'LineWidth',1);
xline(1604,'--');
text(1604,30,'Start brake');
xline(1612,'--');
text(1612,20,'End brake');
legend('Vehicle Speed','Vehicle Yaw Rate','Radar Range','Radar Range Rate','Radar Range Rebuild')
xlabel('Time[s]');

%% Task 3
clc;clear;
load('TableTask2.mat');

participant = SafetyMetricsTable.Test_person;
speed = SafetyMetricsTable.Speed_BO.*3.6;
ttc = SafetyMetricsTable.TTC_BO;
c = participant;
min_acc = SafetyMetricsTable.Min_acc;
mean_acc = SafetyMetricsTable.Mean_acc;

figure(1)
% scatter(speed,ttc,'Weight', ['1','2','3','4'], c,'filled');
% legend;
% xlabel('Speed at brake onset [km/h]');
% ylabel('TTC at brake onset [s]');
gscatter(speed,ttc,c);
xlabel('Speed at brake onset [km/h]');
ylabel('TTC at brake onset [s]');


figure(2)
histogram(ttc);
per = prctile(ttc,[50,95]);
xlabel('TTC at brake onset [s]');
ylabel('Frequency');

figure(3)
subplot(1,2,1)
histogram(mean_acc);
xlabel('Mean acceleration [m/s^2]');
ylabel('Frequency');
subplot(1,2,2)
histogram(min_acc);
xlabel('Minimum acceleration [m/s^2]');
ylabel('Frequency');

%% Task 4
%% Test AEB acc 
AEB_range_rate = ((10:5:80)/3.6);
range = (100:-1:1);
for i = 1:length(AEB_range_rate)
    for j = 1:length(range)
        [act_new(i,j)] = AEB_new(range(j) , AEB_range_rate(i));
        if act_new(i,j) == 1
            dis_acc(i,j) = range(j);
            vel_acc(i,j) = AEB_range_rate(i);
            rem_dis_acc(i,j) = dis_acc(i,j) - (vel_acc(i,j)^2)/18;
        else
            dis_acc(i,j) = 0;
            vel_acc(i,j) = 0;   
            rem_dis_acc(i,j) = 0;
        end
    end
end

%% Test AEB ttc 
AEB_range_rate = (10:5:80)/3.6;
range = 100:-0.01:1;
for i = 1:length(AEB_range_rate)
    for j = 1:length(range)
        [activate_new(i,j)] = AEB_ttc_new(range(j) , AEB_range_rate(i));
        if activate_new(i,j) == 1
            dis_new(i,j) = range(j);
            vel_new(i,j) = AEB_range_rate(i);
            ttc_new(i,j) = range(j)/AEB_range_rate(i);
            rem_dis_new(i,j) = dis_new(i,j) - (vel_new(i,j)^2)/18;           
        else
            dis_new(i,j) = 0;
            vel_new(i,j) = 0;
            ttc_new(i,j) = 0;
            rem_dis_new(i,j) = 0;
        end

    end
end
%% find non 0
[aa,bb] = size(rem_dis_new);
for i = 1:aa
    for j = 1:bb
        if rem_dis_new(i, j) ~= 0
            result_rem(i) = rem_dis_new(i, j);
            break;
        end

    end
end

for i = 1:aa
    for j = 1:bb
        if dis_new(i, j) ~= 0
            result_dis(i) = dis_new(i, j);
            break;
        end

    end
end




%% Test FCW
clc;clear

fcw_threshold = set_threshold(5:-0.1:1, (80:-5:55)/3.6);

lower_threshold = set_threshold(5:-0.1:1, 55/3.6);
%% Visualization FCW ttc 
clc;clear
close all;
initial_va = 90/3.6;
velocity_A = 90/3.6;  
deceleration_A = -5;      
distance_to_B = 200;       
time_step = 0.1;          
current_time = 0;         
fcw_threshold = 4.1;

position_A = 0;
position_B = 200;
x_dash = 0:0.1:1;
y_dash = 0.5;



figure(1)
a = 0;

flag_fcw = 0;
position_A_values = [];
Time_value = [];
vel_FCW = [];


while true
    if flag_fcw == 0
        if FCW_ttc(distance_to_B, velocity_A, fcw_threshold)==1
            plot([position_A,position_A],[-6,6],'--r');
            flag_fcw = 1;
            time_fcw = current_time;
            a = position_A;
            
            
        end
        current_time = current_time + time_step;
        position_A = position_A + velocity_A*time_step;
        distance_to_B = position_B - position_A;
    else
        if (current_time - time_fcw) <= 1.5
            current_time = current_time + time_step;
            position_A = position_A + velocity_A*time_step;
            distance_to_B = position_B - position_A;
        else
            current_time = current_time + time_step;
            velocity_A = velocity_A + deceleration_A*time_step;
            position_A = position_A + (velocity_A + velocity_A-deceleration_A*time_step)*time_step*0.5;
            distance_to_B = position_B - position_A;
        end

    end
    position_A_values = [position_A_values, position_A];
    Time_value = [Time_value, current_time];
    vel_FCW = [vel_FCW,velocity_A];
    if velocity_A <= 0.01 
        break;
    end
    clf;
    hold on;
    fill([0,210,210,0],[-1,-1,2,2],[0.5, 0.5, 0.5]);
    line([0,210],[0.5,0.5],'linestyle','--','color','w','linewidth',2);
    plot(position_A, 0, 'ro-', 'MarkerSize', 5,'MarkerFaceColor','r'); 
    plot(position_B, 0, 'bo-', 'MarkerSize', 5','MarkerFaceColor','b'); 
    txt = ["time = "+roundn(current_time,-1)+'s',"distance driven = "+roundn(position_A,-1)+"m", "distance to obstacle = "+roundn((200 - position_A),-1)+"m","TTC = "+roundn((200-position_A)/velocity_A,-1)+"s"];
    text(10,-3,txt);
    xlim([0, 200 + 10]); 
    ylim([-5, 5]); 
    title('Active Safety Project: Rear-end scenario');
    legend('','','Car A', 'Car B');
    grid on;
    line_fcw = plot([a,a],[2,6],'--r');
    text_fcw = text(a,4,'FCW agg.');



    drawnow;
end

%% Visualization AEB acc 
position_A_values = [];
Time_value = [];
clear;
clc;
clc;clear
close all;
initial_va = 90/3.6;
velocity_A = 90/3.6;        
distance_to_B = 200;       
time_step = 0.1;          
current_time = 0;         
fcw_threshold = 4.1;

position_A = 0;
position_B = 200;
x_dash = 0:0.1:1;
y_dash = 0.5;


figure(2)
flag_aeb = 0;
flag_fcw = 0;
flag_fcw_con = 0;
flag_aeb_acc = 0;
a = 0;
b = 0;
c = 0;
d = 0;
aeb_dec = -9;
AEB_Postion = [];
Time_AEB = [];
Vel_AEB = [];

while true
    if flag_fcw == 0
        if FCW_ttc(distance_to_B, velocity_A, fcw_threshold)==1            
            flag_fcw = 1;        
            a = position_A;
        end
    end

    if flag_fcw_con == 0
        if FCW_ttc(distance_to_B, velocity_A, fcw_threshold + 2.5)==1            
            flag_fcw_con = 1;        
            d = position_A;
        end
    end


    if flag_aeb == 0
        if AEB_ttc_new(distance_to_B, velocity_A)==1
            
            flag_aeb = 1;
            b = position_A;
                  
        end
    end


    if flag_aeb_acc == 0
        if AEB_new(distance_to_B, velocity_A)==1            
            flag_aeb_acc = 1;        
            c = position_A;
        end

        current_time = current_time + time_step;
        position_A = position_A + velocity_A*time_step;
        distance_to_B = position_B - position_A;
    else
        current_time = current_time + time_step;
        velocity_A = velocity_A + aeb_dec*time_step;
        position_A = position_A + (velocity_A + velocity_A-aeb_dec*time_step)*time_step*0.5;
        distance_to_B = position_B - position_A;

    end

    AEB_Postion = [AEB_Postion, position_A];
    Time_AEB = [Time_AEB, current_time];
    Vel_AEB = [Vel_AEB, velocity_A];

    if velocity_A <= 0.01 
        break;
    end

    clf;
    hold on;
    fill([0,210,210,0],[-1,-1,2,2],[0.5, 0.5, 0.5]);
    line([0,210],[0.5,0.5],'linestyle','--','color','w','linewidth',2);
    plot(position_A, 0, 'ro-', 'MarkerSize', 5,'MarkerFaceColor','r'); 
    plot(position_B, 0, 'bo-', 'MarkerSize', 5','MarkerFaceColor','b'); 
    txt = ["time = "+roundn(current_time,-1)+'s',"distance driven = "+roundn(position_A,-1)+"m", "distance to obstacle = "+roundn((200 - position_A),-1)+"m","TTC = "+roundn((200-position_A)/velocity_A,-1)+"s"];
    text(10,-3,txt);
    xlim([0, 200 + 10]); 
    ylim([-5, 5]); 
    title('Active Safety Project: Rear-end scenario');
    legend('','','Car A', 'Car B');
    grid on;
    line_aeb = plot([b,b],[2,6],'--r');
    text_aeb = text(b,4,'AEB ttc.');
    text_fcw = text(a,4,'FCW agg.');
    line_fcw = plot([a,a],[2,6],'--r');
    text_aeb_acc = text(c,-4,'AEB dec.');
    line_aeb_acc = plot([c,c],[-6,-1],'--r');
    text_fcw_con = text(d,4,'FCW con.');
    line_fcw_con = plot([d,d],[2,6],'--r');



    drawnow;
end




%% Plot posi
load('vel_AEB.mat');
load('vel_FCW.mat');
load('Time_AEB.mat');
load('Time_FCW.mat');
load('AEB_Posi.mat');
load('FCW_Posi.mat');
plot(Time_AEB,(200-AEB_Postion),'LineWidth',1)
hold on;
plot(Time_value,(200-position_A_values),'LineWidth',1)
hold on;
plot([0,8],[200,0],'LineWidth',1)


line([3.9,3.9],[0,200],'linestyle','--');
text(3.9,180,'FCW aggr.');
line([4,4],[0,200],'linestyle','--');
text(4,120,'Brake.');
line([1.4,1.4],[0,200],'linestyle','--');
text(1.4,180,'FCW con.');
line([2.9,2.9],[0,200],'linestyle','--');
text(2.9,160,'React');
line([6.7,6.7],[0,200],'linestyle','--');
text(6.7,160,'AEB');
line([8,8],[0,200],'linestyle','--');
text(8,120,'Crash');
legend('AEB activates','FCW activates','No reaction')
xlabel('Time [s]');
ylabel('Distance to lead vehicle [m]');
ylim([0,200]);



%% Plot speed
plot(Time_AEB,Vel_AEB,'LineWidth',2)
hold on;
plot(Time_value,vel_FCW,'LineWidth',2)
hold on;
plot([0,8],[25,25],'LineWidth',2,'Color',[0,0,0])
plot([8,8],[25,0],'LineWidth',2,'Color',[0,0,0])
ylim([0,25]);

line([3.9,3.9],[0,25],'linestyle','--');
text(3.9,20,'FCW aggr.');
line([4,4],[0,25],'linestyle','--');
text(4,15,'Brake.');
line([1.4,1.4],[0,25],'linestyle','--');
text(1.4,20,'FCW con.');
line([2.9,2.9],[0,25],'linestyle','--');
text(2.9,12,'React');
line([6.7,6.7],[0,25],'linestyle','--');
text(6.7,12,'AEB');
line([8,8],[0,25],'linestyle','--');
text(8,12,'Crash');
legend('AEB activates','FCW activates','No reaction')
xlabel('Time [s]');
ylabel('Speed [m/s]');




%% AEB ACC
function [activate] = AEB_new(range , rangeRate)

    acc = -(rangeRate^2)/(2*range);

        if acc <= -7
            activate = 1;
        else
            activate = 0;
        end
end
%% set threshold
function [threshold] = set_threshold(ttc_set, speed_set)
threshold = inf;
for ttc = ttc_set
    crash = 0;
    for speed = speed_set
            if crash == 0
                for range = 100:-1:1
                    if FCW_ttc(range, speed, ttc)==1
                        res_range = range-(1.2*speed+speed^2/(2*4));
                        if res_range < 0 
                            crash = 1;
                        end
                        break;
                    end
                end
            else
                break;
            end
    end
    if crash == 0
        threshold = min(threshold, ttc);
    end
end
end
%% FCW ttc
function [activate] = FCW_ttc(range, rangeRate, threshold)
    system_activated = false;    
    ttc = range/rangeRate;
    
    if ttc < threshold
        system_activated = true;
    end
    if system_activated
        activate = 1;
    else
        activate = 0;
    end
end
%% AEB TTC
function [activate] = AEB_ttc_new(range , rangeRate)
AEB_TTC_low = 0.62;% v = 40 a = -9  min ttc
AEB_TTC_high = 1.3;% v = 80 a = -9  min ttc
AEB_TTC = range/rangeRate;

    if rangeRate < 40/3.6
        if AEB_TTC <= AEB_TTC_low
            activate = 1;
      
        else
            activate = 0;        
        end
    end
    if rangeRate >= 40/3.6
        if AEB_TTC <= AEB_TTC_high
            activate = 1;            
        else
            activate = 0;
            
        end
    end
    
end

