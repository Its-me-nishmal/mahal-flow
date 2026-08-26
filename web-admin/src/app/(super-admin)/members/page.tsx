import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { mockMembers } from "@/lib/mock-data";

export default function MemberManagementPage() {
  return (
    <>
      <PageHeader
        title="Members"
        description="Manage all registered members across the platform."
        actions={
          <a
            href="/members/import"
            className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]"
          >
            <span className="material-symbols-outlined text-[18px]">upload_file</span>
            Import Excel
          </a>
        }
      />

      <div className="flex gap-2 mb-lg">
        {["All", "Active", "Pending", "Suspended"].map((filter, i) => (
          <button
            key={filter}
            className={`h-8 px-4 rounded-full font-button text-small transition-colors ${
              i === 0
                ? "bg-primary-container text-on-primary"
                : "bg-surface border border-border-base text-text-secondary hover:bg-surface-container-low"
            }`}
          >
            {filter}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {mockMembers.map((member) => (
          <div
            key={member.id}
            className={`bg-surface border border-border-base rounded-xl p-lg hover:-translate-y-1 transition-transform duration-200 ${
              member.status === "Suspended" ? "opacity-60" : ""
            }`}
          >
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-button text-button">
                  {member.name
                    .split(" ")
                    .map((n) => n[0])
                    .join("")}
                </div>
                <div>
                  <p className="font-card-title text-card-title text-text-primary">
                    {member.name}
                  </p>
                  <p className="font-small text-small text-text-muted">{member.id}</p>
                </div>
              </div>
              <StatusBadge status={member.status} />
            </div>
            <div className="space-y-2 mb-4">
              <div className="flex items-center gap-2 text-text-secondary">
                <span className="material-symbols-outlined text-[16px]">phone</span>
                <span className="font-body text-body">{member.phone}</span>
              </div>
              <div className="flex items-center gap-2 text-text-secondary">
                <span className="material-symbols-outlined text-[16px]">payments</span>
                <span className="font-body text-body">Monthly Due: {member.dues}</span>
              </div>
              <div className="flex items-center gap-2 text-text-secondary">
                <span className="material-symbols-outlined text-[16px]">calendar_month</span>
                <span className="font-body text-body">Last Paid: {member.lastPaid}</span>
              </div>
            </div>
            <div className="flex gap-2 pt-4 border-t border-border-base">
              <a
                href={`/members/${member.id}`}
                className="flex-1 h-9 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low font-button text-small flex items-center justify-center gap-1 transition-colors"
              >
                <span className="material-symbols-outlined text-[14px]">visibility</span>
                View
              </a>
              <a
                href={`/members/${member.id}/edit`}
                className="flex-1 h-9 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low font-button text-small flex items-center justify-center gap-1 transition-colors"
              >
                <span className="material-symbols-outlined text-[14px]">edit</span>
                Edit
              </a>
            </div>
          </div>
        ))}
      </div>

      <div className="flex justify-center pt-lg">
        <button className="h-11 px-6 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low font-button text-button transition-colors">
          Load More Members
        </button>
      </div>
    </>
  );
}
