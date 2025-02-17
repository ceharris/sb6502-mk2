	.ifndef SOUND_H
		SOUND_H = 1

		SND_ADDR = $80D0
		SND_DATA = SND_ADDR+1

		.global snd_notes

		.global snd_rd_channel_period
		.global snd_wr_channel_period
		.global snd_wr_channel_note
		.global snd_rd_noise_period
		.global snd_wr_noise_period
		.global snd_rd_mixer_control
		.global snd_wr_mixer_control
		.global snd_rd_channel_amplitude
		.global snd_wr_channel_amplitude
		.global snd_rd_envelope_period
		.global snd_wr_envelope_period
		.global snd_rd_envelope_shape
		.global snd_wr_envelope_shape
		.global snd_rd_io_port
		.global snd_wr_io_port
	
	.endif