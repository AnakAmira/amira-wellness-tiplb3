//
//  OnboardingView.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI

/// A SwiftUI view that implements the onboarding experience for the Amira Wellness app,
/// guiding users through a series of screens that introduce the app's key features and privacy-first approach.
struct OnboardingView: View {
    // MARK: - Properties
    
    /// The view model that manages the state and business logic for the onboarding flow
    @ObservedObject var viewModel: OnboardingViewModel
    
    /// Closure to call when onboarding is completed
    var onboardingCompleted: () -> Void
    
    // MARK: - Initialization
    
    /// Initializes the OnboardingView with a view model and completion handler
    /// - Parameters:
    ///   - viewModel: The view model that manages the onboarding state
    ///   - onboardingCompleted: Closure to call when onboarding is completed
    init(viewModel: OnboardingViewModel, onboardingCompleted: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onboardingCompleted = onboardingCompleted
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background color for the entire view
            ColorConstants.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar at the top showing current position in onboarding
                progressBar()
                
                // Skip button for bypassing the remaining pages (hidden on last page)
                if !viewModel.isLastPage() {
                    skipButton()
                }
                
                // Content for the current onboarding page
                pageContent()
                
                Spacer()
                
                // Navigation buttons for moving between pages
                navigationButtons()
            }
            .padding()
            .animation(.easeInOut, value: viewModel.currentPage)
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates the content for the current onboarding page
    private func pageContent() -> some View {
        VStack(spacing: 30) {
            // Page image
            Image(viewModel.getPageImageName())
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .padding(.top, 20)
                .accessibility(label: Text("Onboarding illustration"))
            
            // Page title
            Text(viewModel.getPageTitle())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(label: Text("Page title"))
            
            // Page description
            Text(viewModel.getPageDescription())
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(label: Text("Page description"))
        }
    }
    
    /// Creates the navigation buttons for the onboarding flow
    private func navigationButtons() -> some View {
        VStack(spacing: 16) {
            if viewModel.isLastPage() {
                // On the last page, show a "Get Started" button that completes onboarding
                PrimaryButton(
                    title: "Comenzar",
                    action: onboardingCompleted
                )
                .accessibility(label: Text("Get started"))
            } else {
                // On other pages, show a "Next" button to advance to the next page
                PrimaryButton(
                    title: "Siguiente",
                    action: viewModel.nextPage
                )
                .accessibility(label: Text("Next page"))
                
                // If not on the first page, show a "Back" button to return to the previous page
                if viewModel.currentPage.rawValue > 0 {
                    SecondaryButton(
                        title: "Atrás",
                        action: viewModel.previousPage
                    )
                    .accessibility(label: Text("Previous page"))
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    /// Creates a progress bar showing the current position in the onboarding flow
    private func progressBar() -> some View {
        ProgressView(value: viewModel.getProgressValue())
            .progressViewStyle(LinearProgressViewStyle(tint: ColorConstants.primary))
            .frame(height: 4)
            .padding(.top, 16)
            .accessibility(label: Text("Onboarding progress"))
            .accessibilityValue(Text("\(Int(viewModel.getProgressValue() * 100))% complete"))
    }
    
    /// Creates a skip button for bypassing the onboarding flow
    private func skipButton() -> some View {
        HStack {
            Spacer()
            
            Button("Omitir") {
                viewModel.skipOnboarding()
                onboardingCompleted()
            }
            .font(.subheadline)
            .foregroundColor(ColorConstants.primary)
            .padding(.vertical, 8)
            .accessibility(label: Text("Skip onboarding"))
        }
    }
}