import type { WorkspaceScope } from "@cleanspace/desktop-api";
import { RulesWorkspace } from "../rules/RulesWorkspace";

type Props = { scope: WorkspaceScope };

export function RulesPage({ scope }: Props) {
  return <RulesWorkspace scope={scope} />;
}
