# GRE_template - a QSM template creation pipeline

This code creates a multimodal study-specifi template for GRE derived maps (QSM, SMWI and R2*). This code has been adapted and expanded from Ferdinand Schweser's lab to function at the DCCN in Nijmegen, NL. The template is optimized for imaging of the deep nuclei and basal ganglia. Resolution of the cortex is manageable but less optimal for finegrained anatomical imaging.

Dependencies:
- FSL 6.0.3
- ANTS 2.1.0 (20150225 on DCCN cluster)
- C3d affine tool 1.0.0

The process is as follows:

1. Download this code to a path of your own. Modify the code-path variables in all code files to your own code directory (except the modified antsMultivariateTemplateConstruction2.sh).
2. Derive GRE-derived measures: R2*-maps, SMWI-maps and QSM-maps. Unprocessed T1w-images are also a prerequisite.
3. Create a study-folder (e.g '/project/<project_no>/bids/derivatives/qsm_template', referred to as <main_dir> below) with all derived maps. Naming should be:
- subid_qsm.nii.gz
- subid_t1.nii.gz
- subid_r2s.nii.gz
- subid_smwi.nii.gz, 
with subid as 'sub-001' etc. Add a list with all subject-ids called 'id-list.txt' in the main directory.

4. Do visual QC on GRE-derived measures by running: 
> QC.sh <main_dir> 
5. Run the preprocessing. This is a wrapper that submits subject-specfic preprocessing. It depends on preprocess_sub.sh. Preparing consists of BET, bias-field correction of T1, alignment of GRE-space to T1, and alignment to MNI-space. The command is:
> preprocess_all <main_dir> 
6. If step 2 jobs are completed (runtime ~1.5 hours per job), run the main template creation. Runtime is roughly 4x8 hrs, but dependent on amount of subjects and how busy the cluster is. Command:
> create_template <main_dir>
7. To normalize all subjects to template space, run register_all.sh This is a wrapper for submitting register_sub.sh jobs.
> register_all <main_dir>
