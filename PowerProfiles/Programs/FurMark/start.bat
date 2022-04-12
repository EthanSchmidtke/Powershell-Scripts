rem start FurMark.exe /nogui /width=1024 /height=728 /disable_osi /log_gpu_data /log_gpu_data_polling_factor=60
rem start FurMark.exe /dyn_camera /nogui /width=1024 /height=728
rem start FurMark.exe /preset=1080 /nogui /width=1024 /height=728
rem start FurMark.exe /enable_dyn_bkg=1 /nogui /width=1024 /height=728
rem 
rem /bkg_img_id=1 --> default image in FurMark 1.18.x
rem /bkg_img_id=2 --> default image in FurMark 1.19.x

rem start FurMark.exe /enable_dyn_bkg=1 /bkg_img_id=2 /nogui /width=1024 /height=728

rem Start FurMark with render thread affinity mask set to 2 (like in FurMark 1.19).
rem start FurMark.exe /render_thread_affinity_mask=2



start FurMark.exe /nogui /width=1024 /height=728 /noscore /log_score /log_gpu_data_polling_factor=10 /run_mode=1 /max_time=10000
