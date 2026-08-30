"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { SearchBar } from "@/components/ui/SearchBar";
import { FilterTabs } from "@/components/ui/FilterTabs";
import { EmptyState } from "@/components/ui/EmptyState";
import { ShimmerCardSkeleton } from "@/components/ui/ShimmerSkeleton";
import { ApiClient } from "@/lib/api-client";

export default function MemberManagementPage() {
  const [members, setMembers] = useState<any[]>([]);
  const [filter, setFilter] = useState("All");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form State
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [houseName, setHouseName] = useState("");
  const [duesAmount, setDuesAmount] = useState(500);

  const loadMembers = () => {
    setLoading(true);
    ApiClient.getMembers("MH_001_CALICUT", 1, 100)
      .then((res) => {
        if (res && res.members) {
          setMembers(res.members);
        }
      })
      .catch((err) => console.error("Error loading members:", err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadMembers();
  }, []);

  const handleAddMember = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !phone.trim()) return;

    setIsSubmitting(true);
    try {
      await ApiClient.createMember({
        name,
        phone,
        house_name: houseName,
        monthly_dues_custom_amount: Number(duesAmount) || 500,
        status: "ACTIVE",
        family_head: true,
      });
      setName("");
      setPhone("");
      setHouseName("");
      setDuesAmount(500);
      setShowAddModal(false);
      loadMembers();
    } catch (err) {
      console.error("Failed to add member:", err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const filteredMembers = members.filter((m) => {
    const matchesFilter =
      filter === "All" ||
      (filter === "Active" && m.status === "ACTIVE") ||
      (filter === "Grace Period" && (m.status === "GRACE_PERIOD" || m.status === "PENDING")) ||
      (filter === "Suspended" && (m.status === "SUSPENDED" || m.status === "INACTIVE"));

    const matchesSearch =
      (m.name || "").toLowerCase().includes(search.toLowerCase()) ||
      (m.id || "").toLowerCase().includes(search.toLowerCase()) ||
      (m.phone || "").includes(search) ||
      (m.house_name || "").toLowerCase().includes(search.toLowerCase());

    return matchesFilter && matchesSearch;
  });

  const filterCounts = {
    All: members.length,
    Active: members.filter((m) => m.status === "ACTIVE").length,
    "Grace Period": members.filter((m) => m.status === "GRACE_PERIOD" || m.status === "PENDING").length,
    Suspended: members.filter((m) => m.status === "SUSPENDED" || m.status === "INACTIVE").length,
  };

  return (
    <>
      <PageHeader
        title="Members Directory"
        description="Live MongoDB member registry and automated dues ledger for MH_001_CALICUT."
        actions={
          <div className="flex gap-2">
            <button
              onClick={() => setShowAddModal(true)}
              className="px-4 py-2 bg-primary text-on-primary font-button text-button rounded-lg hover:bg-primary-dark transition-colors flex items-center gap-2 h-[44px] shadow-sm"
            >
              <span className="material-symbols-outlined text-[18px]">person_add</span>
              Add Member
            </button>
            <a
              href="/excel-import"
              className="px-4 py-2 bg-surface border border-border-base text-text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]"
            >
              <span className="material-symbols-outlined text-[18px]">upload_file</span>
              Import Excel
            </a>
          </div>
        }
      />

      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
        <FilterTabs
          options={["All", "Active", "Grace Period", "Suspended"]}
          selected={filter}
          onSelect={setFilter}
          counts={filterCounts}
        />
        <SearchBar
          value={search}
          onChange={setSearch}
          placeholder="Search name, phone, house..."
          className="w-full sm:w-72"
        />
      </div>

      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <ShimmerCardSkeleton key={i} />
          ))}
        </div>
      ) : filteredMembers.length === 0 ? (
        <EmptyState
          icon="group_off"
          title="No Members Found"
          description={
            search
              ? `No matching records found for "${search}". Try searching another name or phone.`
              : `No members found in "${filter}" status.`
          }
          actionLabel={search ? "Clear Search" : "Register Member"}
          onAction={search ? () => setSearch("") : () => setShowAddModal(true)}
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredMembers.map((member) => (
            <div
              key={member.id}
              className={`bg-surface border border-border-base rounded-2xl p-5 hover:border-primary/40 hover:shadow-md transition-all duration-200 ${
                member.status === "SUSPENDED" ? "opacity-60" : ""
              }`}
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-full bg-primary-light text-primary flex items-center justify-center font-button text-sm font-bold border border-primary/20">
                    {(member.name || "M")
                      .split(" ")
                      .map((n: string) => n[0])
                      .join("")
                      .toUpperCase()
                      .slice(0, 2)}
                  </div>
                  <div>
                    <p className="font-card-title text-card-title text-text-primary leading-tight">
                      {member.name}
                    </p>
                    <p className="font-small text-xs text-text-muted mt-0.5">
                      {member.house_name || "Central House"} • {member.member_code || member.id}
                    </p>
                  </div>
                </div>
                <StatusBadge status={member.status} />
              </div>
              <div className="space-y-2 text-xs text-text-secondary border-t border-border-base pt-3">
                <div className="flex justify-between items-center">
                  <span>Phone Number</span>
                  <span className="font-medium text-text-primary">{member.phone}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span>Monthly Rate</span>
                  <span className="font-semibold text-text-primary">
                    ₹{member.monthly_dues_custom_amount || member.monthly_dues || 500}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span>Last Settled Month</span>
                  <span className="font-medium text-text-primary">
                    {member.last_paid_month || "N/A"}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span>Outstanding Balance</span>
                  <span className={`font-bold ${member.outstanding_balance > 0 ? "text-error" : "text-success"}`}>
                    ₹{member.outstanding_balance || 0}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add Member Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-surface rounded-2xl border border-border-base shadow-2xl max-w-md w-full p-6 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-primary-light flex items-center justify-center text-primary">
                  <span className="material-symbols-outlined text-[18px]">person_add</span>
                </div>
                <h3 className="font-card-title text-base font-bold text-text-primary">Register New Member</h3>
              </div>
              <button
                onClick={() => setShowAddModal(false)}
                className="text-text-muted hover:text-text-primary p-1 rounded-lg"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>
            <form onSubmit={handleAddMember} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-text-secondary mb-1">Full Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Abdul Rahman"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full h-10 px-3 border border-border-base rounded-lg text-sm text-text-primary bg-surface outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-text-secondary mb-1">Phone Number *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. +91 98471 22334"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full h-10 px-3 border border-border-base rounded-lg text-sm text-text-primary bg-surface outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-text-secondary mb-1">House Name</label>
                <input
                  type="text"
                  placeholder="e.g. Darussalam"
                  value={houseName}
                  onChange={(e) => setHouseName(e.target.value)}
                  className="w-full h-10 px-3 border border-border-base rounded-lg text-sm text-text-primary bg-surface outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-text-secondary mb-1">Monthly Dues (₹)</label>
                <input
                  type="number"
                  min="50"
                  value={duesAmount}
                  onChange={(e) => setDuesAmount(Number(e.target.value))}
                  className="w-full h-10 px-3 border border-border-base rounded-lg text-sm text-text-primary bg-surface outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 border border-border-base rounded-lg text-text-secondary font-button text-xs font-semibold hover:bg-surface-container-low transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-primary text-on-primary rounded-lg font-button text-xs font-semibold hover:bg-primary-dark transition-colors shadow-sm"
                >
                  {isSubmitting ? "Creating..." : "Save Member"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
