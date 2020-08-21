let Hooks = {};

const createAudio = () => {
    const context = new AudioContext();
    const oscillator = context.createOscillator();
    oscillator.type = "triangle";
    oscillator.frequency.value = 432;

    const gain = context.createGain();
    gain.gain.value = 0;

    oscillator.connect(gain);
    gain.connect(context.destination);

    oscillator.start(0);

    return {
        on: () => gain.gain.value = 0.2,
        off: () => gain.gain.value = 0,
        close: () => context.close()
    }
}

Hooks.Screen = {
    mounted() {
        this.handleEvent("screen_init", () => {
            this.synth = this.synth || createAudio();
        });
        this.handleEvent("screen_soundcard_emit", ({value}) => {
            if (value) {
                this.synth?.on();
            } else {
                this.synth?.off();
            }
        });
    },
    beforeDestroy() {
        this.synth?.close();
    },
    disconnected() {
        this.synth?.off();
    }
}

export {
    Hooks
};