#include "uvisor-lib/uvisor-lib.h"
#include "mbed.h"
#include "rtos.h"
#include "main-hw.h"

struct box_context {
    Thread * thread;
    uint32_t heartbeat;
};

static const UvisorBoxAclItem acl[] = {
};

static void led1_main(const void *);

UVISOR_BOX_NAMESPACE(NULL);
UVISOR_BOX_HEAPSIZE(2048);
UVISOR_BOX_MAIN(led1_main, osPriorityNormal, 1024);
UVISOR_BOX_CONFIG(box_led1, acl, 1024, box_context);

static void led1_main(const void *)
{
    DigitalOut led1(LED1);
    led1 = LED_OFF;

    while (1) {
		if (led1) {
			printf("LED off : _\n");
		} else {
			printf("LED on  : #\n");
		}
        led1 = !led1;
        ++uvisor_ctx->heartbeat;
        for (int i = 0; i < 0x100000; i++);
    }
}
