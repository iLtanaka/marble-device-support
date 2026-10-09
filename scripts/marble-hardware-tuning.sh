#!/bin/sh
# marble-hardware-tuning.sh: move busy IRQs off CPU 0 (GICv3 routes every SPI to CPU 0 by default)

set_irq_affinity() {
    pat="$1"
    mask="$2"
    for irq in $(awk -v pat="$pat" '$0 ~ pat { gsub(":", "", $1); print $1 }' /proc/interrupts); do
        if [ -w "/proc/irq/$irq/smp_affinity" ]; then
            echo "$mask" > "/proc/irq/$irq/smp_affinity"
        fi
    done
}

# Touchscreen and GPU -> CPUs 4-6 (Cortex-A710)
set_irq_affinity "goodix-berlin" "70"
set_irq_affinity "gpu-irq" "70"

# UFS -> CPUs 1-3 (Cortex-A510, off CPU 0)
set_irq_affinity "ufshcd" "0e"
