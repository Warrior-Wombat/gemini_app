import pyaudio
import wave
from io import BytesIO

def record_audio(duration=5, sample_rate=16000, channels=1, chunk=1024):
    p = pyaudio.PyAudio()
    stream = p.open(format=pyaudio.paInt16,
                    channels=channels,
                    rate=sample_rate,
                    input=True,
                    frames_per_buffer=chunk)

    print("Recording...")
    frames = []
    for _ in range(0, int(sample_rate / chunk * duration)):
        data = stream.read(chunk)
        frames.append(data)
    print("Recording finished.")

    stream.stop_stream()
    stream.close()
    p.terminate()

    audio_data = BytesIO()
    wf = wave.open(audio_data, 'wb')
    wf.setnchannels(channels)
    wf.setsampwidth(p.get_sample_size(pyaudio.paInt16))
    wf.setframerate(sample_rate)
    wf.writeframes(b''.join(frames))
    wf.close()

    audio_data.seek(0)
    return audio_data
