import SwiftUI
import Contacts
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    var onSelect: (CNContact) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: (CNContact) -> Void

        init(onSelect: @escaping (CNContact) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let store = CNContactStore()
            let onSelect = self.onSelect

            // Request contacts authorization so we can re-fetch with image data keys.
            // The picker itself doesn't grant CNContactStore access.
            store.requestAccess(for: .contacts) { granted, _ in
                var resultContact = contact

                if granted {
                    let keysToFetch: [CNKeyDescriptor] = [
                        CNContactGivenNameKey as CNKeyDescriptor,
                        CNContactFamilyNameKey as CNKeyDescriptor,
                        CNContactEmailAddressesKey as CNKeyDescriptor,
                        CNContactPhoneNumbersKey as CNKeyDescriptor,
                        CNContactThumbnailImageDataKey as CNKeyDescriptor,
                        CNContactImageDataKey as CNKeyDescriptor,
                    ]

                    if let fullContact = try? store.unifiedContact(
                        withIdentifier: contact.identifier,
                        keysToFetch: keysToFetch
                    ) {
                        resultContact = fullContact
                    }
                }

                DispatchQueue.main.async {
                    onSelect(resultContact)
                }
            }
        }
    }
}
