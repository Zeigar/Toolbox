function out = hmri_run_proc_pipeline(job)
% Deal with the preprocessing pipelines.
%
% Input include only some parametric maps, the structural maps (for
% segmentation), the required smoothing and which pipeline to use. All
% other options are hard-coded!
%  For more flexibility, individual modules can be combined. :-)
%_______________________________________________________________________
% Copyright (C) 2017 Cyclotron Research Centre

% Written by Christophe Phillips

% proc_pipeline = tbx_scfg_hmri_proc_pipeline; [~, job_pipe] = harvest(proc_pipeline, proc_pipeline, false, false);

% 1/ Setup the smoothing and execute hmri_run_proc_US
%----------------------------------------------------
% Get the proc_US job structure, with all the defaults
proc_us = tbx_scfg_hmri_proc_US;
[~, job_US] = harvest(proc_us, proc_us, false, false);

% Fill in the data now: parametric maps & structurals for segmentation
job_US.many_sdatas.vols_pm = job.vols_pm;
job_US.many_sdatas.rstruct.s_vols = job.s_vols;

% Run the *_proc_US
out_US = hmri_run_proc_US(job_US);
% where the output structure 'out_US'
% .tiss : struct-array with subfields
%           .c and .rc, for the native and Dartel imported
%           .wc and .mwc, for the warped and modulated
%         tissue class images
% .maps : struct-array with subfields 'wvols_pm' for the warped parametric
%         maps
% .def  : cell-array with the deformations for each subject.

% 2/ Proceed with dartel (only of requested)
%-------------------------------------------
% including tempalte create and warping into MNI space

if job.pipe_c == 2
    % DARTEM processing
end

% 3/ Deal with smoothing, with hmri_run_proc_smooth
%--------------------------------------------------
proc_smooth = tbx_scfg_hmri_proc_smooth;
[~, job_smooth] = harvest(proc_smooth, proc_smooth, false, false);

% Get the image data, working only with mwc1 and mwc2 (GM and WM)
switch job.pipe_c
    case 1 % US+smooth
        job_smooth = fill_fn_from_US(job_smooth,out_US);
    case 2 % US+Dartel+smooth
        % Fit in DARTEL data
    otherwise
end
% Get the smoothing kernel
job_smooth.fwhm = job.fwhm;

% run the *_proc_smooth
out_wa = hmri_run_proc_smooth(job_smooth);
% where 'out_wa' structure is organized as a structure out.tc.map.fn where
% - tc is an array (1 x n_TCs) with 1 element per tissue class considered
% - map is an array (1 x n_pams) with 1 element per parametric map
% - fn is a cell array (n_subj x 1) with each subject's smoothed data for 
%   the i^th TC and j^th MPM.


% 4/ Collect output and as needed
out = out_wa; % -> good enouh for the moment!

end

%%_________________________________________________________________________
%
% SUBFUNCTION
%__________________________________________________________________________


function job_smooth = fill_fn_from_US(job_smooth,out_US)
% Fill in the filenames of images (parametric maps and tissue classes) for
% the US+smooth pipeline.

% Parametric maps -> use all of them
N_pm = numel(out_US.maps);
for ii=1:N_pm
    job_smooth.vols_pm{ii} = out_US.maps(ii).wvols_pm;
end
% Tissue classes -> use GM and WM, i.e. #1 and #2
for ii=1:2
    job_smooth.vols_tc{ii} = spm_file(out_US.tiss(ii).mwc,'number',1);
end

% NOTE:
% Not sure it's necessary to add the ',1' to specify the volume for the
% tissue class maps but that's how it looks when using the module with the
% batch gui -> saty on the safe side and apply.

end

