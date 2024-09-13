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
%Create the structure that saves the results
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
        new_data(i).Brake = 1;             %According to the acceleration limit braking conditions, 
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
            xline(new_data(i).VehicleTime(start_i),'--');
            xline(new_data(i).VehicleTime(end_i),'--');
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
%By viewing the images, the three sets of data which did not meet the requirements were removed manually (43, 39, 27,20)
remove_row_test = [43, 39, 27, 20];
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



% remove_row = [43, 39, 27, 20, 2, 11, 12, 21, 23, 25, 28, 29, 32, 36, 38, 41, 45, 46, 47, 49, 51, 54, 57, 62, 64, 67, 79];
% results_table(remove_row, :) = [];
% 
% old_name = {'Participant', 'Meanacceleration','Minimumacceleration', ...
%                  'Speedatbrakeonset','Rangeatbrakeonset', ...
%                    'TTCatbrakeonset'};
% table_name = {'Participant', 'Mean acceleration [m/s^2]','Minimum acceleration [m/s^2]', ...
%                  'Speed at brakeonset [m/s]','Range at brake onset [m]', ...
%                    'TTC at brake onset [s]'};
% results_table = renamevars(results_table,old_name,table_name);
