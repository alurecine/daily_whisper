import SwiftUI

struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: toast.style.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(toast.style.color)
                .padding(.top, toast.message == nil ? 0 : 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                if let msg = toast.message, !msg.isEmpty {
                    Text(msg)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(Color(.systemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }
}

