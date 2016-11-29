//: Playground - noun: a place where people can play

import UIKit

/*
 Original example taken from here: http://hotcocoatouch.com/2016/11/16/composite-validators/
 
 We'll use Functional Swift book to build functional version of composite validator
 */

enum ValidatorResult {
    case valid
    case invalid(error: Error)
}

protocol Validator {
    func validate(string: String) -> ValidatorResult
}

enum EmailValidatorError: Error {
    case empty
    case invalidFormat
}

enum PasswordValidatorError: Error {
    case empty
    case tooShort
    case noUppercaseLetter
    case noLowercaseLetter
    case noNumber
}

struct EmptyStringValidator: Validator {

    // This error is passed via the initializer to allow this validator to be reused
    private let invalidError: Error

    init(invalidError: Error) {
        self.invalidError = invalidError
    }

    func validate(string: String) -> ValidatorResult {
        return string.isEmpty ? .invalid(error: invalidError) : .valid
    }

}

struct EmailFormatValidator: Validator {

    func validate(string: String) -> ValidatorResult {
        let magicEmailRegexStolenFromTheInternet = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", magicEmailRegexStolenFromTheInternet)
        return emailTest.evaluate(with: string) ? .valid : .invalid(error: EmailValidatorError.invalidFormat)
    }

}

struct PasswordLengthValidator: Validator {

    func validate(string: String) -> ValidatorResult {
        return string.characters.count >= 8 ? .valid : .invalid(error: PasswordValidatorError.tooShort)
    }

}

struct UppercaseLetterValidator: Validator {

    func validate(string: String) -> ValidatorResult {
        let uppercaseLetterRegex = ".*[A-Z]+.*"
        let uppercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", uppercaseLetterRegex)
        return uppercaseLetterTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noUppercaseLetter)
    }
    
}

struct LowercaseLetterValidator: Validator {

    func validate(string: String) -> ValidatorResult {
        let lowercaseLetterRegex = ".*[a-z]+.*"
        let lowercaseLetterTest = NSPredicate(format: "SELF MATCHES %@", lowercaseLetterRegex)
        return lowercaseLetterTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noLowercaseLetter)
    }
    
}

struct ContainsNumberValidator: Validator {

    func validate(string: String) -> ValidatorResult {
        let containsNumberRegex = ".*[0-9]+.*"
        let containsNumberTest = NSPredicate(format: "SELF MATCHES %@", containsNumberRegex)
        return containsNumberTest.evaluate(with: string) ? .valid : .invalid(error: PasswordValidatorError.noNumber)
    }

}

struct CompositeValidator: Validator {

    private let validators: [Validator]

    init(validators: [Validator]) {
        self.validators = validators
    }

    func validate(string: String) -> ValidatorResult {
        for validator in validators {
            switch validator.validate(string: string) {
            case .invalid(let error):
                return .invalid(error: error)
            case .valid:
                break
            }
        }
        return .valid
    }

}

struct ValidatorConfigurator {

    static func emailValidator() -> Validator {
        let validators: [Validator] = [emptyEmailStringValidator(), EmailFormatValidator()]
        return CompositeValidator(validators: validators)
    }

    static func passwordValidator() -> Validator {
        let validators: [Validator] = [emptyPasswordStringValidator(), passwordStrengthValidator()]
        return CompositeValidator(validators: validators)
    }

    // MAKR: Private

    private static func emptyEmailStringValidator() -> Validator {
        return EmptyStringValidator(invalidError: EmailValidatorError.empty)
    }

    private static func emptyPasswordStringValidator() -> Validator {
        return EmptyStringValidator(invalidError: PasswordValidatorError.empty)
    }

    private static func passwordStrengthValidator() -> Validator {
        let validators: [Validator] = [PasswordLengthValidator(),
                                       UppercaseLetterValidator(),
                                       LowercaseLetterValidator(),
                                       PasswordLengthValidator()]
        return CompositeValidator(validators: validators)
    }

}

// MARK: Testing

let emailValidator = ValidatorConfigurator.emailValidator()
let passwordValidator = ValidatorConfigurator.passwordValidator()

print(emailValidator.validate(string: ""))
print(emailValidator.validate(string: "invalidEmail@"))
print(emailValidator.validate(string: "validEmail@validDomain.com"))

print(passwordValidator.validate(string: ""))
print(passwordValidator.validate(string: "psS$"))
print(passwordValidator.validate(string: "passw0rd"))
print(passwordValidator.validate(string: "paSSw0rd"))
