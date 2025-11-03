import SwiftData
import SwiftUI

struct LegendsView: View {
    @Query(
        filter: #Predicate<UserGesture> { $0.isEnabled == true },
        sort: [SortDescriptor(\UserGesture.order)]
    ) private var enabledGestures: [UserGesture]
    
    private var legendItems: [LegendItem] {
        enabledGestures.map(LegendItem.init)
    }
    
    private var hasMultipleColumns: Bool {
        legendItems.count > 6
    }
    
    private var columnItems: [[LegendItem]] {
        guard !legendItems.isEmpty else { return [] }
        if !hasMultipleColumns { return [legendItems] }
        let midPoint = Int(ceil(Double(legendItems.count) / 2.0))
        let left = Array(legendItems.prefix(midPoint))
        let rightCount = max(legendItems.count - midPoint, 0)
        let right = rightCount > 0 ? Array(legendItems.suffix(rightCount)) : []
        return right.isEmpty ? [left] : [left, right]
    }
    
    var body: some View {
        let items = legendItems
        
        return VStack(alignment: .leading, spacing: 13) {
            Text("LEGENDS")
                .font(Typography.montserratBoldBody)
                .foregroundColor(.black)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 262.70313, height: 1)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            
            if items.isEmpty {
                Text("No gestures selected yet.")
                    .font(Typography.legendLabel)
                    .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
                    .padding(.vertical, 14)
            } else if hasMultipleColumns {
                HStack(alignment: .top, spacing: 13) {
                    ForEach(Array(columnItems.enumerated()), id: \.offset) { _, column in
                        LegendColumn(items: column)
                    }
                }
            } else {
                LegendColumn(items: items)
            }
        }
    }
}

private struct LegendItem: Identifiable {
    let id: UUID
    let title: String
    let imageName: String
    let usesSystemImage: Bool
    
    init(_ userGesture: UserGesture) {
        id = userGesture.id
        title = userGesture.displayName.uppercased()
        if let assetName = userGesture.gestureType.legendAssetName {
            imageName = assetName
            usesSystemImage = false
        } else {
            imageName = userGesture.gestureType.iconName
            usesSystemImage = true
        }
    }
}

private struct LegendColumn: View {
    let items: [LegendItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                LegendRow(item: item)
            }
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 14)
        .frame(alignment: .topLeading)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(20)
    }
}

private struct LegendRow: View {
    let item: LegendItem
    
    var body: some View {
        HStack(alignment: .center) {
            Text(item.title)
                .font(Typography.legendLabel)
                .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
            Spacer()
            legendIcon
                .frame(width: 19.2, height: 19.2)
        }
    }
    
    @ViewBuilder
    private var legendIcon: some View {
        if item.usesSystemImage {
            Image(systemName: item.imageName)
                .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
        } else {
            Image(item.imageName)
            
        }
    }
}

#Preview {
    let schema = Schema([
        AACard.self,
        ActionCombo.self,
        GridPosition.self,
        UserGesture.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext
    SampleData.populate(context: context)
    if let gestures = try? context.fetch(FetchDescriptor<UserGesture>(sortBy: [SortDescriptor(\.order)])) {
        for (index, gesture) in gestures.enumerated() where index < 8 {
            gesture.isEnabled = true
        }
        try? context.save()
    }
    
    return LegendsView()
        .modelContainer(container)
}
