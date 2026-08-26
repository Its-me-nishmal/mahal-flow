import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { mockMahals } from "@/lib/mock-data";

export default function MahalDirectoryPage() {
  return (
    <>
      <PageHeader
        title="Mahal Directory"
        description="Manage all registered Mahals across the platform."
        actions={
          <a
            href="/mahals/new"
            className="px-4 py-2 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2 h-[44px]"
          >
            <span className="material-symbols-outlined text-[18px]">add</span>
            Add New Mahal
          </a>
        }
      />

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                search
              </span>
              <input
                className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full sm:w-72 h-[44px] focus:border-primary focus:ring-0 outline-none"
                placeholder="Search Mahals..."
                type="text"
              />
            </div>
            <button className="h-[44px] px-3 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low transition-colors flex items-center justify-center gap-2">
              <span className="material-symbols-outlined">filter_list</span>
              Filter
            </button>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  MAHAL NAME
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  LOCATION
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  STATUS
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  MEMBERS
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  PLAN
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap text-right">
                  ACTIONS
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {mockMahals.map((mahal) => (
                <tr key={mahal.id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center shrink-0 border border-border-base">
                        <span className="material-symbols-outlined text-text-secondary text-[20px]">
                          mosque
                        </span>
                      </div>
                      <div>
                        <p className="font-button text-button text-text-primary">
                          {mahal.name}
                        </p>
                        <p className="font-small text-small text-text-muted">
                          {mahal.id}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {mahal.location}
                  </td>
                  <td className="py-4 px-lg">
                    <StatusBadge status={mahal.status} />
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {mahal.members.toLocaleString()}
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">
                    {mahal.plan}
                  </td>
                  <td className="py-4 px-lg text-right">
                    <div className="flex items-center justify-end gap-1">
                      <a
                        href={`/mahals/${mahal.id}`}
                        className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors"
                      >
                        <span className="material-symbols-outlined">visibility</span>
                      </a>
                      <a
                        href={`/mahals/${mahal.id}/edit`}
                        className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors"
                      >
                        <span className="material-symbols-outlined">edit</span>
                      </a>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="p-md border-t border-border-base flex items-center justify-between bg-surface-container-lowest">
          <p className="font-small text-small text-text-secondary">
            Showing 1 to {mockMahals.length} of {mockMahals.length} entries
          </p>
          <div className="flex gap-1">
            <button className="h-8 px-3 bg-primary-container text-on-primary font-button text-small rounded-lg">
              1
            </button>
            <button className="h-8 px-3 text-text-secondary hover:bg-surface-container-low font-button text-small rounded-lg">
              2
            </button>
            <button className="h-8 px-3 text-text-secondary hover:bg-surface-container-low font-button text-small rounded-lg">
              3
            </button>
          </div>
        </div>
      </div>
    </>
  );
}
