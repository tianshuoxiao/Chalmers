function [ dataParticipant ] = LOAD_simulatorData( LOADED, eventType )
%UNTITLED9 Summary of this function goes here
%   Detailed explanation goes here
EventLength = length(LOADED.Event.(eventType).SYNC.Timeseries.Timestamps);
dataParticipant.EventLength = EventLength;


sampleRate_s = mode(diff(LOADED.Event.(eventType).SYNC.Timeseries.Timestamps))/1000;
dataParticipant.sampleRate_seconds = sampleRate_s;

IDX_warning = find(LOADED.Event.(eventType).SYNC.Timeseries.EGO_Warning_onset, 1, 'first');
dataParticipant.IDX_warning = IDX_warning;


dataParticipant.Time_relative_to_warning_s = [[1:1:EventLength] - IDX_warning].*sampleRate_s;

% Lane ID (...||4|| 5 | 6 | 7 || : 6 is the middle lane)
EGOinLane = LOADED.Event.(eventType).SYNC.Timeseries.EGO_in_lane;
dataParticipant.EGO_in_Lane = EGOinLane;

% ID 2 is the one that brakes in front of the EGO vehicle
POV_IDfront = LOADED.Event.(eventType).SYNC.Timeseries.POVfront_ID;
dataParticipant.POV_IDfront = POV_IDfront;

IDX_filter_POV_front = (EGOinLane == 6) & (POV_IDfront == 2);

POVfrontlength = LOADED.Event.(eventType).SYNC.Timeseries.POVfront_length(1);
dataParticipant.POV_front_length = POVfrontlength;

POVfrontwidth = LOADED.Event.(eventType).SYNC.Timeseries.POVfront_width(1);
dataParticipant.POV_front_width = POVfrontwidth;

EGO_speed = LOADED.Event.(eventType).SYNC.Timeseries.EGO_longitudinal_speed;
dataParticipant.EGO_speed = EGO_speed;

EGO_longitudinal_acceleration = LOADED.Event.(eventType).SYNC.Timeseries.EGO_longitudinal_acceleration;
dataParticipant.EGO_longitudinal_acceleration = EGO_longitudinal_acceleration;

EGO_lateral_acceleration = LOADED.Event.(eventType).SYNC.Timeseries.EGO_lateral_acceleration;
dataParticipant.EGO_lateral_acceleration = EGO_lateral_acceleration;

EGO_steerAngle = LOADED.Event.(eventType).SYNC.Timeseries.EGO_steering_angle;
dataParticipant.EGO_steerAngle = EGO_steerAngle;

EGO_steerAngleRate = [diff(EGO_steerAngle)./sampleRate_s nan];
dataParticipant.EGO_steerAngleRate = EGO_steerAngleRate;

EGO_steerAngleJerk = [diff(EGO_steerAngleRate)./sampleRate_s nan];
dataParticipant.EGO_steerAngleJerk = EGO_steerAngleJerk;

distCoG_long = nan(1, EventLength);
distCoG_long(IDX_filter_POV_front) = LOADED.Event.(eventType).SYNC.Timeseries.POVfront_CoG_longitudinal_distance_to_EGO_CoG(IDX_filter_POV_front);
dataParticipant.EGO_POV_longitudinal_distance_CoG = distCoG_long;

dist_lat_CoG = nan(1, EventLength);
dist_lat_CoG(IDX_filter_POV_front) = LOADED.Event.(eventType).SYNC.Timeseries.POVfront_CoG_lateral_distance_to_EGO_CoG(IDX_filter_POV_front);
dataParticipant.EGO_POV_lateral_distance_CoG = dist_lat_CoG;

range_long = nan(1, EventLength);
range_long(IDX_filter_POV_front) = LOADED.Event.(eventType).SYNC.Timeseries.POVfront_fender_to_fender_longitudinal_distance(IDX_filter_POV_front);
dataParticipant.EGO_POV_fender_to_fender_range = range_long;

range_rate_long = [diff(range_long)./sampleRate_s nan];
dataParticipant.EGO_POV_fender_to_fender_rangeRate = range_rate_long;

end

