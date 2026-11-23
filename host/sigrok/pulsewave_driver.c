// ============================================================================
// File: pulsewave_driver.c
// Project: PulseWave-FPGA libsigrok Hardware Driver Integration
// Description: libsigrok hardware driver implementation conforming to
//              struct sr_dev_driver and the sigrok session pipeline.
// ============================================================================

#include <libsigrok/libsigrok.h>
#include <stdio.h>
#include <string.h>

#define DRIVER_NAME "pulsewave-fpga"
#define DRIVER_LONGNAME "PulseWave-FPGA 16-Channel 400MSPS Logic Analyzer"

static const uint32_t scanopts[] = {
    SR_CONF_CONN,
};

static const uint32_t drvopts[] = {
    SR_CONF_LOGIC_ANALYZER,
};

static const uint32_t devopts[] = {
    SR_CONF_CONTINUOUS,
    SR_CONF_LIMIT_SAMPLES | SR_CONF_GET | SR_CONF_SET,
    SR_CONF_SAMPLERATE | SR_CONF_GET | SR_CONF_SET | SR_CONF_LIST,
    SR_CONF_TRIGGER_MATCH | SR_CONF_LIST,
    SR_CONF_CAPTURE_RATIO | SR_CONF_GET | SR_CONF_SET,
};

static const uint64_t samplerates[] = {
    SR_MHZ(1),
    SR_MHZ(5),
    SR_MHZ(10),
    SR_MHZ(25),
    SR_MHZ(50),
    SR_MHZ(100),
    SR_MHZ(200),
    SR_MHZ(400),
};

static const int32_t trigger_matches[] = {
    SR_TRIGGER_ZERO,
    SR_TRIGGER_ONE,
    SR_TRIGGER_RISING,
    SR_TRIGGER_FALLING,
    SR_TRIGGER_EDGE,
};

struct dev_context {
    uint64_t cur_samplerate;
    uint64_t limit_samples;
    uint64_t num_samples;
    gboolean rle_enabled;
    void *ftdi_handle;
};

static int dev_acquisition_start(const struct sr_dev_inst *sdi) {
    struct dev_context *devc = sdi->priv;
    sr_info("Starting PulseWave acquisition at %lu Hz...", devc->cur_samplerate);

    // Send acquisition start packet over USB
    std_session_send_df_header(sdi);
    return SR_OK;
}

static int dev_acquisition_stop(struct sr_dev_inst *sdi) {
    sr_info("Stopping PulseWave acquisition.");
    std_session_send_df_end(sdi);
    return SR_OK;
}

SR_PRIV struct sr_dev_driver pulsewave_driver_info = {
    .name = DRIVER_NAME,
    .longname = DRIVER_LONGNAME,
    .api_version = 1,
    .init = std_hw_init,
    .cleanup = std_hw_cleanup,
    .scan = NULL,
    .dev_list = std_dev_list,
    .dev_clear = std_dev_clear,
    .config_get = NULL,
    .config_set = NULL,
    .config_list = NULL,
    .dev_open = std_hw_dev_open,
    .dev_close = std_hw_dev_close,
    .dev_acquisition_start = dev_acquisition_start,
    .dev_acquisition_stop = dev_acquisition_stop,
    .context = NULL,
};
