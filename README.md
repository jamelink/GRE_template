# GRE_template

This code creates a multimodal study-specifi template for GRE derived maps (QSM, SMWI and R2*). This code has been adapted and expanded from Ferdinand Schweser's lab to function at the DCCN. The template is optimized for imaging of the deep nuclei and basal ganglia. Resolution of the cortex is manageable but less optimal for finegrained anatomical imaging.

Dependencies:
FSL
ANTS
C3d affine etool

The main pipeline is as follows:

0. Derive GRE-derived measures: R2*-maps, SMWI-maps and QSM-maps. Unprocessed T1w-images are also a prerequisite.
1. Create a study-folder with all derived maps. Naming should be <subid>_qsm.nii.gz, <subid>_t1.nii.gz, <subid>_r2s.nii.gz and <subid>_smwi.nii.gz
2. Run the preprocess_all.sh. This is a wrapper that submits subject-specfic preprocessing. It depends on preprocess_sub.sh. Preparing consists of BET, bias-field correction of T1, alignment of GRE-space to T1, and alignment to MNI-space.
3. If step 2 jobs are completed (runtime ~1.5 hours per job), run the main template creation. Runtime is roughly 4x8 hrs, but dependent on amount of subjects and how busy the cluster is.
4. To normalize all subjects to template space, run register_all.sh This is once again dependent on register_sub.sh.
