import type { Variants, Transition } from 'framer-motion'

const spring: Transition = {
  type: 'spring',
  stiffness: 300,
  damping: 30,
}

const smooth: Transition = {
  type: 'tween',
  ease: [0.25, 0.1, 0.25, 1],
  duration: 0.3,
}

export const fadeIn: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: smooth },
  exit: { opacity: 0, transition: { duration: 0.15 } },
}

export const fadeInUp: Variants = {
  hidden: { opacity: 0, y: 12 },
  visible: { opacity: 1, y: 0, transition: smooth },
  exit: { opacity: 0, y: -6, transition: { duration: 0.15 } },
}

export const fadeInDown: Variants = {
  hidden: { opacity: 0, y: -12 },
  visible: { opacity: 1, y: 0, transition: smooth },
  exit: { opacity: 0, y: 6, transition: { duration: 0.15 } },
}

export const slideInRight: Variants = {
  hidden: { opacity: 0, x: 24 },
  visible: { opacity: 1, x: 0, transition: smooth },
  exit: { opacity: 0, x: 24, transition: { duration: 0.15 } },
}

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.95 },
  visible: { opacity: 1, scale: 1, transition: spring },
  exit: { opacity: 0, scale: 0.95, transition: { duration: 0.15 } },
}

export const stagger: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.05 },
  },
}

export const staggerItem: Variants = {
  hidden: { opacity: 0, y: 8 },
  visible: { opacity: 1, y: 0, transition: smooth },
}

export const pageTransition: Variants = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0, transition: smooth },
  exit: { opacity: 0, y: -8, transition: { duration: 0.15 } },
}

export { spring, smooth }