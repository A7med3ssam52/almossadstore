import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
    "inline-flex items-center justify-center whitespace-nowrap rounded-2xl text-sm font-black transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#1F2933] disabled:pointer-events-none disabled:opacity-50 active:scale-95",
    {
        variants: {
            variant: {
                default: "bg-[#1F2933] text-white shadow-lg shadow-[#1F2933]/30 hover:bg-[#3A3F45]",
                destructive: "bg-red-500 text-white hover:bg-red-600",
                outline: "border border-white/10 bg-white/5 hover:bg-white/10 text-white",
                secondary: "bg-white/10 text-white hover:bg-white/20",
                ghost: "hover:bg-white/5 text-gray-400 hover:text-white",
                link: "text-[#1F2933] underline-offset-4 hover:underline",
            },
            size: {
                default: "h-11 px-6 py-2",
                sm: "h-9 rounded-xl px-4 text-xs",
                lg: "h-14 rounded-3xl px-10 text-base",
                icon: "h-11 w-11",
            },
        },
        defaultVariants: {
            variant: "default",
            size: "default",
        },
    }
)

const Button = React.forwardRef(({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
        <Comp
            className={cn(buttonVariants({ variant, size, className }))}
            ref={ref}
            {...props}
        />
    )
})
Button.displayName = "Button"

export { Button, buttonVariants }
