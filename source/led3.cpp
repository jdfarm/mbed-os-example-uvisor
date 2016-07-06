#include "fun_bag.h"
#include "uvisor-lib/uvisor-lib.h"
#include "mbed.h"
#include "rtos.h"
#include "main-hw.h"

struct box_context {
    Thread * thread;
    Thread * thread2;
    Thread * thread3;
    uint32_t heartbeat;
    int toggle;
};

static const UvisorBoxAclItem acl[] = {
};

static void led3_main(const void *);

UVISOR_BOX_NAMESPACE(NULL);
UVISOR_BOX_HEAPSIZE(2048);
UVISOR_BOX_MAIN(led3_main, osPriorityNormal, 512);
UVISOR_BOX_CONFIG(box_led3, acl, 512, box_context);

static void run_3(const void *)
{
    while (1) {
        const int toggle = uvisor_ctx->toggle;
        uint16_t size = toggle ? 150 : 99;
        uint16_t seed = (size << 8) | (uvisor_ctx->heartbeat & 0xFF);

        uvisor_ctx->toggle = !uvisor_ctx->toggle;
        alloc_fill_wait_verify_free(size, seed, 0);
    }
}

static void led3_main(const void *)
{
    DigitalOut led3(LED3);
    led3 = LED_OFF;
    uvisor_ctx->thread2 = new Thread(run_3);
    uvisor_ctx->thread3 = new Thread(run_3);

    /* Create page-backed allocator. */
    const uint32_t kB = 1024;
    SecureAllocator alloc = secure_allocator_create_with_pages(4*kB, 1*kB);
    /* Prepare the thread definition structure. */
    osThreadDef_t thread_def;
    thread_def.stacksize = DEFAULT_STACK_SIZE;
    /* Allocate the stack inside the page allocator! */
    thread_def.stack_pointer = (uint32_t *) secure_malloc(alloc, DEFAULT_STACK_SIZE);
    thread_def.tpriority = osPriorityNormal;
    thread_def.pthread = &run_3;
    /* Create a thread with the page allocator as heap. */
    osThreadContextCreate(&thread_def, NULL, alloc);


    while (1) {
        static const size_t size = 20;
        uint16_t seed = (size << 8) | (uvisor_ctx->heartbeat & 0xFF);

        led3 = !led3;
        ++uvisor_ctx->heartbeat;
        alloc_fill_wait_verify_free(size, seed, 211);
    }
}
