function [ dataParticipant ] = LOAD_annotations( SOURCE, Participant, EventType, dataParticipant)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

SOURCE.CodingSchemaFile = fullfile(SOURCE.experimentDataFolder,...
    'codingSchema.json');
codingSchema = loadjson(SOURCE.CodingSchemaFile);

toBeLoaded_ANNOTATION = fullfile(SOURCE.dataParticipantsFolder,...
    Participant, ...
    sprintf('annotation_%s_%s.mat', Participant, EventType));

if exist(toBeLoaded_ANNOTATION, 'file') == 2
    
    LOADED_ANNOTATION = load(toBeLoaded_ANNOTATION);
    
    for iAnn = 1 : length(codingSchema.schema)
        
        if strcmp(codingSchema.schema{iAnn}.variable, 'Feet')
            IDX_hoverOverBrake_first = find(LOADED_ANNOTATION.annotations.(codingSchema.schema{iAnn}.variable) == find(ismember(codingSchema.schema{iAnn}.categories, 'Hovering over brake pedal'))-1,...
                1, 'first');
            if isempty(IDX_hoverOverBrake_first), IDX_hoverOverBrake_first = nan; end
            
            IDX_brakeInitiated_first = find(LOADED_ANNOTATION.annotations.(codingSchema.schema{iAnn}.variable) == find(ismember(codingSchema.schema{iAnn}.categories, 'Braking'))-1,...
                1, 'first');
            if isempty(IDX_brakeInitiated_first), IDX_brakeInitiated_first = nan; end
            
            IDX_hoverOverAccelerator_first = find(LOADED_ANNOTATION.annotations.(codingSchema.schema{iAnn}.variable) == find(ismember(codingSchema.schema{iAnn}.categories, 'Hovering over accelerator pedal'))-1,...
                1, 'first');
            if isempty(IDX_hoverOverAccelerator_first), IDX_hoverOverAccelerator_first = nan; end
            
            IDX_accelerationInitiated_first = find(LOADED_ANNOTATION.annotations.(codingSchema.schema{iAnn}.variable) == find(ismember(codingSchema.schema{iAnn}.categories, 'Accelerating'))-1,...
                1, 'first');
            
            if isempty(IDX_accelerationInitiated_first), IDX_accelerationInitiated_first = nan; end
            
            dataParticipant.first_frame_hovering_over_brake_pedal = IDX_hoverOverBrake_first;
            dataParticipant.first_frame_braking = IDX_brakeInitiated_first;
            dataParticipant.first_frame_hovering_over_accelerator_pedal = IDX_hoverOverAccelerator_first;
            dataParticipant.first_frame_accelerating = IDX_accelerationInitiated_first;
        
        elseif strcmp(codingSchema.schema{iAnn}.variable, 'Hands')
            IDX_HandsOnWheel_first = find(LOADED_ANNOTATION.annotations.(codingSchema.schema{iAnn}.variable) == find(ismember(codingSchema.schema{iAnn}.categories, 'Hands on wheel'))-1,...
                1, 'first');
            if isempty(IDX_HandsOnWheel_first), IDX_HandsOnWheel_first = nan; end
            
            dataParticipant.first_frame_hands_on_wheel = IDX_HandsOnWheel_first;
        end
        
        
    end
else
    warning('!!! %s not found !!! ', toBeLoaded_ANNOTATION)
end



end

