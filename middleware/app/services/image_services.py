import io
import subprocess
from io import BytesIO

def convert_to_wav(audio_buffer: BytesIO) -> BytesIO:
    audio_buffer.seek(0)

    process = subprocess.Popen(
        ['ffmpeg', '-i', '-', '-ac', '1', '-ar', '16000', '-f', 'wav', '-'],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )

    wav_data, error = process.communicate(input=audio_buffer.read())

    if process.returncode != 0:
        raise ValueError(f"FFmpeg error: {error.decode()}")

    return io.BytesIO(wav_data)
