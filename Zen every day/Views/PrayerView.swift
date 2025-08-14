// PrayerView.swift
import SwiftUI

struct PrayerView: View {
  @EnvironmentObject var settings: UserSettings
  @StateObject private var prayerManager = PrayerManager()

  @State private var title = ""
  @State private var content = ""
  @State private var showEmptyAlert = false
  @State private var isAddingPrayer = false
  @State private var selectedPrayer: Prayer?
  @State private var showingDeleteAlert = false
  @State private var prayerToDelete: Prayer?
  @State private var prayerToShare: Prayer?

  // Edit functionality
  @State private var isEditingPrayer = false
  @State private var prayerToEdit: Prayer?

  var body: some View {
    VStack(spacing: 0) {
      // Header
      VStack(spacing: 16) {
        // Title and subtitle
        VStack(spacing: 4) {
          Text("Prayer Journal")
            .font(.title2)
            .fontWeight(.bold)

          Text("Write down your prayers and reflections")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.top)

        // Add Prayer Button
        Button(action: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if isEditingPrayer {
              cancelEditing()
            }
            isAddingPrayer.toggle()
          }
        }) {
          HStack {
            Image(
              systemName: (isAddingPrayer || isEditingPrayer)
                ? "xmark.circle.fill" : "plus.circle.fill"
            )
            .font(.system(size: 20))
            Text((isAddingPrayer || isEditingPrayer) ? "Cancel" : "New Prayer")
              .font(.system(size: 16, weight: .semibold))
          }
          .foregroundColor(.white)
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 25)
              .fill((isAddingPrayer || isEditingPrayer) ? Color.gray : Color.blue)
          )
        }
        .padding(.bottom, 8)
      }
      .frame(maxWidth: .infinity)
      .background(Color(.systemGroupedBackground))

      // New/Edit Prayer Form (Collapsible)
      if isAddingPrayer || isEditingPrayer {
        VStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Title (Optional)")
              .font(.caption)
              .foregroundColor(.secondary)

            TextField("Give your prayer a title", text: $title)
              .font(.system(size: 16))
              .padding(12)
              .background(
                RoundedRectangle(cornerRadius: 10)
                  .fill(Color(.systemGray6))
              )
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Prayer")
              .font(.caption)
              .foregroundColor(.secondary)

            TextEditor(text: $content)
              .font(.system(size: 16))
              .padding(8)
              .frame(minHeight: 120)
              .scrollContentBackground(.hidden)
              .background(
                RoundedRectangle(cornerRadius: 10)
                  .fill(Color(.systemGray6))
              )
              .overlay(
                Group {
                  if content.isEmpty {
                    Text("Write your prayer here...")
                      .font(.system(size: 16))
                      .foregroundColor(.secondary.opacity(0.5))
                      .padding(.horizontal, 12)
                      .padding(.vertical, 16)
                      .allowsHitTesting(false)
                  }
                },
                alignment: .topLeading
              )
          }

          // Save button
          Button(action: isEditingPrayer ? updatePrayer : savePrayer) {
            Text(isEditingPrayer ? "Update Prayer" : "Save Prayer")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(content.isEmpty ? Color.gray : Color.blue)
              )
          }
          .disabled(content.isEmpty)
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .transition(
          .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
          ))
      }

      // Prayers List
      ScrollView {
        if prayerManager.prayers.isEmpty {
          // Empty state
          VStack(spacing: 20) {
            Image(systemName: "hands.sparkles")
              .font(.system(size: 60))
              .foregroundColor(.secondary.opacity(0.5))

            Text("No prayers yet")
              .font(.title3)
              .fontWeight(.medium)
              .foregroundColor(.secondary)

            Text("Tap 'New Prayer' to add your first prayer")
              .font(.system(size: 15))
              .foregroundColor(.secondary.opacity(0.8))
              .multilineTextAlignment(.center)
          }
          .padding(.top, 80)
          .frame(maxWidth: .infinity)
        } else {
          LazyVStack(spacing: 12) {
            ForEach(prayerManager.prayers.sorted { $0.date > $1.date }) { prayer in
              PrayerCard(
                prayer: prayer,
                isExpanded: selectedPrayer?.id == prayer.id,
                onTap: {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedPrayer = selectedPrayer?.id == prayer.id ? nil : prayer
                  }
                },
                onEdit: {
                  startEditing(prayer: prayer)
                },
                onShare: {
                  prayerToShare = prayer
                },
                onDelete: {
                  prayerToDelete = prayer
                  showingDeleteAlert = true
                }
              )
              .environmentObject(settings)
            }
          }
          .padding()
        }
      }
      .background(Color(.systemGroupedBackground))
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $prayerToShare) { prayer in
      let shareText = [prayer.title, prayer.content]
        .compactMap { $0 }
        .joined(separator: "\n\n")
      ShareSheet(items: [shareText])
    }
    .alert("Prayer cannot be empty", isPresented: $showEmptyAlert) {
      Button("OK", role: .cancel) {}
    }
    .alert("Delete Prayer?", isPresented: $showingDeleteAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let prayer = prayerToDelete {
          withAnimation {
            prayerManager.deletePrayer(prayer)
            if selectedPrayer?.id == prayer.id {
              selectedPrayer = nil
            }
          }
        }
      }
    } message: {
      Text("This prayer will be permanently deleted.")
    }
  }

  private func savePrayer() {
    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedContent.isEmpty {
      showEmptyAlert = true
    } else {
      let newPrayer = Prayer(
        title: title.isEmpty ? nil : title,
        content: trimmedContent
      )
      prayerManager.addPrayer(newPrayer)

      // Reset form
      title = ""
      content = ""

      // Close form with animation
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        isAddingPrayer = false
      }
    }
  }

  private func startEditing(prayer: Prayer) {
    // Close any existing form first
    if isAddingPrayer {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        isAddingPrayer = false
      }
    }

    prayerToEdit = prayer
    title = prayer.title ?? ""
    content = prayer.content

    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      isEditingPrayer = true
    }

    debugLog("DEBUG: Started editing prayer with ID: \(prayer.id)")
  }

  private func updatePrayer() {
    guard let originalPrayer = prayerToEdit else {
      debugLog("DEBUG: No prayer to edit")
      return
    }

    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedContent.isEmpty {
      showEmptyAlert = true
    } else {
      debugLog("DEBUG: Updating prayer with ID: \(originalPrayer.id)")
      debugLog("DEBUG: Original content: '\(originalPrayer.content.prefix(50))...'")
      debugLog("DEBUG: New content: '\(trimmedContent.prefix(50))...'")

      // First, remove the old prayer
      prayerManager.deletePrayer(originalPrayer)

      // Then add the updated prayer with the same ID and date
      let updatedPrayer = Prayer(
        id: originalPrayer.id,
        title: title.isEmpty ? nil : title,
        content: trimmedContent,
        date: originalPrayer.date
      )

      prayerManager.addPrayer(updatedPrayer)

      // Reset form
      title = ""
      content = ""
      self.prayerToEdit = nil

      // Close form with animation
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        isEditingPrayer = false
      }

      debugLog("DEBUG: Prayer update completed")
    }
  }

  private func cancelEditing() {
    title = ""
    content = ""
    prayerToEdit = nil

    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      isAddingPrayer = false
      isEditingPrayer = false
    }
  }
}

// Enhanced Prayer Card Component with Edit functionality
struct PrayerCard: View {
  let prayer: Prayer
  let isExpanded: Bool
  let onTap: () -> Void
  let onEdit: () -> Void
  let onShare: () -> Void
  let onDelete: () -> Void
  @EnvironmentObject var settings: UserSettings

  var displayTitle: String {
    if let title = prayer.title, !title.isEmpty {
      return title
    } else {
      // Use first line of content as title
      let firstLine = prayer.content.components(separatedBy: .newlines).first ?? ""
      return firstLine.isEmpty ? "Prayer" : String(firstLine.prefix(50))
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text(displayTitle)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(isExpanded ? nil : 1)

          Text(formattedDate(prayer.date))
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        // Actions
        HStack(spacing: 12) {
          Button(action: onEdit) {
            Image(systemName: "pencil.circle")
              .font(.system(size: 20))
              .foregroundColor(.blue)
          }

          Button(action: onShare) {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 20))
              .foregroundColor(.blue)
          }

          Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              onTap()
            }
          }) {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
              .font(.system(size: 20))
              .foregroundColor(.blue)
          }

          Button(action: onDelete) {
            Image(systemName: "trash.circle")
              .font(.system(size: 20))
              .foregroundColor(.red.opacity(0.7))
          }
        }
      }

      // Content (expandable)
      if isExpanded {
        Text(prayer.content)
          .font(.system(size: settings.fontSize))
          .foregroundColor(.primary.opacity(0.9))
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 4)
          .transition(
            .asymmetric(
              insertion: .scale(scale: 0.95).combined(with: .opacity),
              removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
      } else if prayer.title != nil {
        // Show preview of content if there's a separate title
        Text(prayer.content)
          .font(.system(size: 14))
          .foregroundColor(.secondary)
          .lineLimit(2)
          .padding(.top, 2)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.secondarySystemGroupedBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
    .contentShape(Rectangle())
    .onTapGesture {
      onTap()
    }
  }

  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
      formatter.timeStyle = .short
      return "Today at \(formatter.string(from: date))"
    } else if calendar.isDateInYesterday(date) {
      formatter.timeStyle = .short
      return "Yesterday at \(formatter.string(from: date))"
    } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
      formatter.dateFormat = "EEEE 'at' h:mm a"
      return formatter.string(from: date)
    } else {
      formatter.dateStyle = .medium
      formatter.timeStyle = .short
      return formatter.string(from: date)
    }
  }
}

struct PrayerView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      PrayerView()
        .environmentObject(UserSettings())
    }
  }
}
