ffmpeg -i input.mov -vf "fps=30" -pix_fmt yuv420p -c:v libx264 -profile:v high -level:v 4.0 -preset slow -crf 18 -c:a aac -b:a 192k output_high_quality.mp4

ffmpeg -i input.mp4 -vf "hflip" -c:a copy output_flipped.mp4

ffmpeg -i input.mp4 -vf "subtitles=subs.srt" -c:a copy output_with_subs.mp4
