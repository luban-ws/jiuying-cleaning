import type { SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement>;

const defaults: IconProps = {
  width: 20,
  height: 20,
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.75,
  strokeLinecap: "round",
  strokeLinejoin: "round",
  "aria-hidden": true,
};

export function IconVolumes(props: IconProps) {
  return (
    <svg {...defaults} {...props}>
      <path d="M4 7h16v10a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7Z" />
      <path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
    </svg>
  );
}

export function IconDocker(props: IconProps) {
  return (
    <svg {...defaults} {...props}>
      <path d="M3 10h2v2H3zM6 10h2v2H6zM9 10h2v2H9zM6 7h2v2H6zM9 7h2v2H9z" fill="currentColor" stroke="none" />
      <path d="M12 10h2v2h-2zM15 10h2v2h-2zM12 7h2v2h-2z" fill="currentColor" stroke="none" />
      <path d="M3 14h14a3 3 0 0 1 3 3v1H3v-4z" />
    </svg>
  );
}

export function IconMonitor(props: IconProps) {
  return (
    <svg {...defaults} {...props}>
      <path d="M4 5h16v11H4z" />
      <path d="M8 19h8" />
    </svg>
  );
}

export function IconRules(props: IconProps) {
  return (
    <svg {...defaults} {...props}>
      <path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01" />
    </svg>
  );
}

export function IconAiTools(props: IconProps) {
  return (
    <svg {...defaults} {...props}>
      <path d="m12 3 1.2 3.6L17 8l-3.6 1.2L12 13l-1.2-3.8L7 8l3.8-1.2L12 3Z" />
      <path d="M5 16l.8 2.4L8 19l-2.2.8L5 22l-.8-2.2L2 19l2.2-.6L5 16Z" />
      <path d="M19 14l.6 1.8L21 16l-1.4.5L19 18l-.6-1.5L17 16l1.4-.5L19 14Z" />
    </svg>
  );
}

export function IconPerformance(props: IconProps) {
  return (
    <svg {...defaults} {...props}>
      <path d="M12 14a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.26.6.77 1.02 1.39 1.15H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z" />
    </svg>
  );
}

export function IconInfo(props: IconProps) {
  return (
    <svg {...defaults} {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 10v6M12 7h.01" />
    </svg>
  );
}

export function IconBrand(props: IconProps) {
  return (
    <svg {...defaults} width={24} height={24} {...props}>
      <path d="M12 3 4 9v12h16V9l-8-6Z" />
      <path d="M9 21v-6h6v6" />
    </svg>
  );
}
