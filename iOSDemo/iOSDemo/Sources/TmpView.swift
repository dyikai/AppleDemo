import SwiftUI

struct TmpView: View {
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Rectangle()
                    .foregroundColor(.red)
                    .frame(width: 200, height: 200)
                
                Rectangle()
                    .fill(.green)
                    .frame(width: 100, height: 100)
            }
            .frame(width: 300, height: 300, alignment: .leading)
            .background(.orange)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.red)
                    .frame(width: 200, height: 200)
                
                Rectangle()
                    .fill(.green)
                    .frame(width: 100, height: 100)
            }
            .frame(width: 300, height: 300)
            .background(.orange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.blue)
    }
}

#Preview {
    TmpView()
}
