import { IconInfo } from "./icons";

type Props = {
  text: string;
};

/** 工作区顶部引导条（设计系统：信息条 + SVG 图标，无 emoji）。 */
export function WorkspaceGuide({ text }: Props) {
  return (
    <p className="guide-banner">
      <span className="guide-icon" aria-hidden>
        <IconInfo width={18} height={18} />
      </span>
      <span>{text}</span>
    </p>
  );
}
