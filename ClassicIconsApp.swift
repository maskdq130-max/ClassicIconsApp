import SwiftUI
import PhotosUI

@main
struct GlassIconsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var wallpaperImage: UIImage?
    @State private var overlayColor: Color = .blue
    @State private var opacity: Double = 0.4
    @State private var blurRadius: Double = 10.0
    @State private var generatedIcon: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("1. Выбери свои обои")) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(wallpaperImage == nil ? "Выбрать обои с экрана Домой" : "Изменить обои")
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                wallpaperImage = image
                                generatePreview()
                            }
                        }
                    }
                }
                
                if wallpaperImage != nil {
                    Section(header: Text("2. Кастомизация цвета и стекла")) {
                        ColorPicker("Цвет оттенка", selection: $overlayColor)
                            .onChange(of: overlayColor) { _ in generatePreview() }
                        
                        VStack(alignment: .leading) {
                            Text("Прозрачность: \(Int(opacity * 100))%")
                            Slider(value: $opacity, in: 0.1...0.9, step: 0.05)
                                .onChange(of: opacity) { _ in generatePreview() }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Размытие (Blur): \(Int(blurRadius))")
                            Slider(value: $blurRadius, in: 0...30, step: 1)
                                .onChange(of: blurRadius) { _ in generatePreview() }
                        }
                    }
                    
                    Section(header: Text("Результат (Превью иконки)")) {
                        HStack {
                            Spacer()
                            if let generatedIcon {
                                Image(uiImage: generatedIcon)
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(radius: 5)
                            }
                            Spacer()
                        }
                        .padding(.vertical)
                        
                        Button(action: saveToPhotos) {
                            HStack {
                                Spacer()
                                Text("Сохранить иконку в «Фото»")
                                    .bold()
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Glass Theme Generator")
        }
    }
    
    // Генерация легкой плавной прозрачной иконки
    private func generatePreview() {
        guard let base = wallpaperImage else { return }
        
        let size = CGSize(width: 180, height: 180)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let result = renderer.image { ctx in
            // 1. Берем фрагмент обоев
            let rect = CGRect(origin: .zero, size: size)
            base.draw(in: rect)
            
            // 2. Накладываем выбранный цвет с прозрачностью
            UIColor(overlayColor).withAlphaComponent(opacity).setFill()
            ctx.fill(rect, blendMode: .normal)
        }
        
        self.generatedIcon = result
    }
    
    private func saveToPhotos() {
        guard let generatedIcon else { return }
        UIImageWriteToSavedPhotosAlbum(generatedIcon, nil, nil, nil)
    }
}
