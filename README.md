# GRE_template

This code creates a multimodal study-specifi template for GRE derived maps (QSM, SMWI and R2*). This code has been adapted and expanded from Ferdinand Schweser's lab to function at the DCCN. The template is optimized for imaging of the deep nuclei and basal ganglia. Resolution of the cortex is manageable but less optimal for finegrained anatomical imaging.

Dependencies:
- FSL 6.0.3
- ANTS 2015.02
- C3d affine etool

The process is as follows:

1. Download this code. Modify the code-path variables in all code files to your own code directory (except the modified antsMultivariateTemplateConstruction2.sh).
2. Derive GRE-derived measures: R2*-maps, SMWI-maps and QSM-maps. Unprocessed T1w-images are also a prerequisite.
3. Do visual QC on GRE-derived measures by running the QC-codes and inspecting the corresponding html files

Then the template code:
4. Create a study-folder with all derived maps. Naming should be <subid>_qsm.nii.gz, <subid>_t1.nii.gz, <subid>_r2s.nii.gz and <subid>_smwi.nii.gz
5. Run the preprocess_all.sh. This is a wrapper that submits subject-specfic preprocessing. It depends on preprocess_sub.sh. Preparing consists of BET, bias-field correction of T1, alignment of GRE-space to T1, and alignment to MNI-space.
6. If step 2 jobs are completed (runtime ~1.5 hours per job), run the main template creation. Runtime is roughly 4x8 hrs, but dependent on amount of subjects and how busy the cluster is.
7. To normalize all subjects to template space, run register_all.sh This is once again dependent on register_sub.sh. 
