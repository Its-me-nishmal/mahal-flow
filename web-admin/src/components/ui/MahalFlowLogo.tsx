import React from "react";
import Image from "next/image";

interface MahalFlowLogoProps {
  size?: "sm" | "md" | "lg" | "xl";
  showText?: boolean;
  className?: string;
  variant?: "light" | "dark" | "colored";
}

export const MahalFlowLogo: React.FC<MahalFlowLogoProps> = ({
  size = "md",
  showText = true,
  className = "",
  variant = "colored",
}) => {
  const sizeMap = {
    sm: { height: 24, width: 88, iconSize: 24 },
    md: { height: 32, width: 120, iconSize: 32 },
    lg: { height: 44, width: 160, iconSize: 44 },
    xl: { height: 56, width: 210, iconSize: 56 },
  };

  const config = sizeMap[size];

  if (!showText) {
    // Isolated Geometric Emblem Vector
    return (
      <svg
        width={config.iconSize}
        height={config.iconSize}
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className={`flex-shrink-0 ${className}`}
      >
        <path
          d="M20 50C20 33.4315 33.4315 20 50 20C58.2843 20 65.8143 23.3579 71.2132 28.7868L60.6066 39.3934C57.8863 36.6731 54.0931 35 50 35C41.7157 35 35 41.7157 35 50C35 54.0931 36.6731 57.8863 39.3934 60.6066L28.7868 71.2132C23.3579 65.8143 20 58.2843 20 50Z"
          fill="#146C5B"
        />
        <path
          d="M80 50C80 66.5685 66.5685 80 50 80C41.7157 80 34.1857 76.6421 28.7868 71.2132L39.3934 60.6066C42.1137 63.3269 45.9069 65 50 65C58.2843 65 65 58.2843 65 50C65 45.9069 63.3269 42.1137 60.6066 39.3934L71.2132 28.7868C76.6421 34.1857 80 41.7843 80 50Z"
          fill="#146C5B"
        />
        <rect
          x="50"
          y="38"
          width="17"
          height="17"
          rx="2"
          transform="rotate(45 50 38)"
          fill="#146C5B"
        />
      </svg>
    );
  }

  return (
    <div className={`flex items-center gap-2.5 select-none ${className}`}>
      <div className="relative overflow-hidden rounded-lg">
        <Image
          src="/brand/logo.png"
          alt="MahalFlow Logo"
          width={config.width}
          height={config.height}
          className="object-contain"
          priority
        />
      </div>
    </div>
  );
};
